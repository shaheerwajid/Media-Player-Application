package com.mediaplayer.music.player.videoplayer

import android.app.*
import android.content.*
import android.media.MediaPlayer
import android.os.*
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import android.media.audiofx.Equalizer
import android.media.audiofx.BassBoost
import android.media.audiofx.Virtualizer
import android.media.audiofx.PresetReverb
import android.content.ContentValues
import android.provider.MediaStore
import android.media.RingtoneManager
import android.provider.Settings
import android.net.Uri
import android.util.Log
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.graphics.BitmapFactory
import android.support.v4.media.MediaMetadataCompat
import android.os.Handler
import android.os.Looper

class AudioPlayerService : Service() {
	companion object {
		const val CHANNEL_ID = "audio_playback_channel"
		const val NOTIFICATION_ID = 1
		const val ACTION_START = "ACTION_START"
		const val ACTION_PAUSE = "ACTION_PAUSE"
		const val ACTION_PLAY = "ACTION_PLAY"
		const val ACTION_NEXT = "ACTION_NEXT"
		const val ACTION_PREVIOUS = "ACTION_PREVIOUS"
		const val ACTION_SEEK = "ACTION_SEEK"
		const val ACTION_STOP = "ACTION_STOP"
		const val ACTION_SET_SPEED = "ACTION_SET_SPEED"
		var instance: AudioPlayerService? = null
		fun setAsRingtone(context: Context, filePath: String): Boolean {
			if (!Settings.System.canWrite(context)) {
				val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
				intent.data = Uri.parse("package:" + context.packageName)
				intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				context.startActivity(intent)
				Log.e("Ringtone", "WRITE_SETTINGS permission not granted.")
				return false
			}
			return try {
				val file = java.io.File(filePath)
				if (!file.exists()) return false

				val values = ContentValues().apply {
					put(MediaStore.MediaColumns.TITLE, file.nameWithoutExtension)
					put(MediaStore.MediaColumns.MIME_TYPE, "audio/mp3")
					put(MediaStore.MediaColumns.SIZE, file.length())
					put(MediaStore.Audio.Media.IS_RINGTONE, true)
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
						put(MediaStore.MediaColumns.RELATIVE_PATH, "Ringtones/")
					} else {
						put(MediaStore.MediaColumns.DATA, file.absolutePath)
					}
				}

				val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
				val newUri = context.contentResolver.insert(uri, values)
				if (newUri == null) return false

				// For Android 10+ (Q), copy the file to the newUri
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
					context.contentResolver.openOutputStream(newUri)?.use { output ->
						file.inputStream().use { input ->
							input.copyTo(output)
						}
					}
				}

				RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, newUri)
				true
			} catch (e: Exception) {
				Log.e("Ringtone", "Failed to set as ringtone", e)
				false
			}
		}
	}

	private var mediaPlayer: MediaPlayer? = null
	private var equalizer: Equalizer? = null
	private var bassBoost: BassBoost? = null
	private var virtualizer: Virtualizer? = null
	private var reverb: PresetReverb? = null
	private var eqEnabled: Boolean = true
	private var eqPreset: Int = 0
	private var reverbPreset: Int = 0
	private var bassBoostStrength: Int = 0
	private var virtualizerStrength: Int = 0
	private var playbackSpeed: Float = 1.0f
	private var currentFilePath: String? = null
	private lateinit var mediaSession: MediaSessionCompat
	private var playbackStateUpdateHandler: Handler? = null
	private var playbackStateUpdateRunnable: Runnable? = null

	override fun onBind(intent: Intent?): IBinder? = null

	override fun onCreate() {
		super.onCreate()
		instance = this
		createNotificationChannel()
		// Initialize MediaSession
		mediaSession = MediaSessionCompat(this, "AudioPlayerService")
		mediaSession.isActive = true
		mediaSession.setCallback(object : MediaSessionCompat.Callback() {
			override fun onPlay() {
				playAudio()
			}
			override fun onPause() {
				pauseAudio()
			}
			override fun onSkipToNext() {
				// Option 2: Notify Flutter to handle next
				sendFlutterAction("next")
			}
			override fun onSkipToPrevious() {
				// Option 2: Notify Flutter to handle previous
				sendFlutterAction("previous")
			}
			override fun onStop() {
				stopAudioExternally()
				stopSelf()
			}
			override fun onSeekTo(pos: Long) {
				seekTo(pos.toInt())
			}
		})
		playbackStateUpdateHandler = Handler(Looper.getMainLooper())
	}

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		when (intent?.action) {
			ACTION_START -> {
				val filePath = intent.getStringExtra("filePath")
				val position = intent.getIntExtra("position", 0)
				startAudio(filePath, position)
			}
			ACTION_PAUSE -> pauseAudio()
			ACTION_PLAY -> playAudio()
			ACTION_NEXT -> nextAudio()
			ACTION_PREVIOUS -> previousAudio()
			ACTION_SEEK -> {
				val position = intent.getIntExtra("position", 0)
				seekTo(position)
			}
			ACTION_STOP -> stopAudioExternally()
			ACTION_SET_SPEED -> {
				val speed = intent.getFloatExtra("speed", 1.0f)
				setPlaybackSpeedInternal(speed)
			}
		}
		return START_STICKY
	}

	private fun sendPlaybackState(state: String) {
		val position = mediaPlayer?.currentPosition ?: 0
		val duration = mediaPlayer?.duration ?: 0
		val event = mutableMapOf<String, Any>(
			"state" to state,
			"position" to position,
			"duration" to duration,
		)
		currentFilePath?.let { event["filePath"] = it }
		EventBridge.eventSink?.success(event)
	}

	private fun startAudio(filePath: String?, position: Int) {
		if (filePath == null) return
		currentFilePath = filePath
		mediaPlayer?.release()
		equalizer?.release()
		bassBoost?.release()
		virtualizer?.release()
		reverb?.release()
		mediaPlayer = MediaPlayer().apply {
			setDataSource(filePath)
			prepare()
			seekTo(position)
			start()
			setOnCompletionListener {
				sendPlaybackState("completed")
				stopSelf()
			}
		}
		// Initialize audio effects after MediaPlayer is prepared
		val sessionId = mediaPlayer!!.audioSessionId
		equalizer = Equalizer(0, sessionId)
		equalizer?.enabled = eqEnabled
		if (eqPreset > 0 && eqPreset < equalizer?.numberOfPresets ?: 0) {
			equalizer?.usePreset(eqPreset.toShort())
		}
		bassBoost = BassBoost(0, sessionId)
		bassBoost?.setStrength(bassBoostStrength.toShort())
		bassBoost?.enabled = eqEnabled
		if (!eqEnabled) bassBoost?.setStrength(0)
		virtualizer = Virtualizer(0, sessionId)
		virtualizer?.setStrength(virtualizerStrength.toShort())
		virtualizer?.enabled = eqEnabled
		if (!eqEnabled) virtualizer?.setStrength(0)
		reverb = PresetReverb(0, sessionId)
		reverb?.preset = reverbPreset.toShort()
		reverb?.enabled = eqEnabled
		// Set media session metadata (with duration)
		val durationMs = mediaPlayer?.duration?.toLong() ?: 0L
		val metadata = MediaMetadataCompat.Builder()
			.putString(MediaMetadataCompat.METADATA_KEY_TITLE, filePath.substringAfterLast('/'))
			.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "Unknown Artist")
			.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Unknown Album")
			.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
			// .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, albumArtBitmap)
			.build()
		mediaSession.setMetadata(metadata)
		showNotification(isPlaying = true)
		sendPlaybackState("playing")
		updateMediaSessionState(true)
		startPlaybackStateUpdates()
	}

	private fun pauseAudio() {
		mediaPlayer?.pause()
		showNotification(isPlaying = false)
		sendPlaybackState("paused")
		updateMediaSessionState(false)
		stopPlaybackStateUpdates()
	}

	private fun playAudio() {
		mediaPlayer?.start()
		showNotification(isPlaying = true)
		sendPlaybackState("playing")
		updateMediaSessionState(true)
		startPlaybackStateUpdates()
	}

	private fun setPlaybackSpeedInternal(speed: Float) {
		playbackSpeed = speed
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			mediaPlayer?.let {
				try {
					it.playbackParams = it.playbackParams.setSpeed(speed)
				} catch (_: Exception) {}
			}
		}
	}

	fun getPlaybackSpeed(): Float = playbackSpeed

	private fun nextAudio() {
		// Implement logic to play next audio file if you have a playlist
		sendPlaybackState("next")
	}

	private fun previousAudio() {
		// Implement logic to play previous audio file if you have a playlist
		sendPlaybackState("previous")
	}

	private fun seekTo(position: Int) {
		mediaPlayer?.seekTo(position)
		sendPlaybackState(if (mediaPlayer?.isPlaying == true) "playing" else "paused")
	}

	private fun showNotification(isPlaying: Boolean) {
		val playPauseAction = if (isPlaying) {
			NotificationCompat.Action(
				android.R.drawable.ic_media_pause, "Pause",
				getPendingIntent(ACTION_PAUSE)
			)
		} else {
			NotificationCompat.Action(
				android.R.drawable.ic_media_play, "Play",
				getPendingIntent(ACTION_PLAY)
			)
		}
		val nextAction = NotificationCompat.Action(
			android.R.drawable.ic_media_next, "Next",
			getPendingIntent(ACTION_NEXT)
		)
		val prevAction = NotificationCompat.Action(
			android.R.drawable.ic_media_previous, "Previous",
			getPendingIntent(ACTION_PREVIOUS)
		)
		val stopAction = NotificationCompat.Action(
			android.R.drawable.ic_menu_close_clear_cancel, "Stop",
			getPendingIntent(ACTION_STOP)
		)

		val mediaStyle = androidx.media.app.NotificationCompat.MediaStyle()
			.setMediaSession(mediaSession.sessionToken)
			.setShowActionsInCompactView(1) // Show play/pause in compact view

		val notification = NotificationCompat.Builder(this, CHANNEL_ID)
			.setContentTitle("Audio Playing")
			.setContentText("Your audio is playing")
			.setSmallIcon(android.R.drawable.ic_media_play)
			.addAction(prevAction)
			.addAction(playPauseAction)
			.addAction(nextAction)
			.addAction(stopAction)
			.setStyle(mediaStyle)
			.setOngoing(isPlaying)
			.build()

		startForeground(NOTIFICATION_ID, notification)
	}

	private fun getPendingIntent(action: String): PendingIntent {
		val intent = Intent(this, AudioPlayerService::class.java).apply { this.action = action }
		return PendingIntent.getService(this, action.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
	}

	private fun createNotificationChannel() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channel = NotificationChannel(
				CHANNEL_ID,
				"Audio Playback",
				NotificationManager.IMPORTANCE_LOW
			)
			val manager = getSystemService(NotificationManager::class.java)
			manager.createNotificationChannel(channel)
		}
	}

	override fun onDestroy() {
		instance = null
		sendPlaybackState("stopped")
		mediaPlayer?.release()
		equalizer?.release()
		bassBoost?.release()
		virtualizer?.release()
		reverb?.release()
		currentFilePath = null
		stopPlaybackStateUpdates()
		super.onDestroy()
	}

	// Add a method to stop audio externally
	fun stopAudioExternally() {
		mediaPlayer?.stop()
		sendPlaybackState("stopped")
		currentFilePath = null
		stopSelf()
	}

	// Equalizer accessors for MethodChannel
	fun getEqualizerBands(): Int {
		return equalizer?.numberOfBands?.toInt() ?: 0
	}
	fun getEqualizerBandLevelRange(): ShortArray? {
		return equalizer?.bandLevelRange
	}
	fun getEqualizerBandLevel(band: Int): Short {
		return equalizer?.getBandLevel(band.toShort()) ?: 0
	}
	fun setEqualizerBandLevel(band: Int, level: Short) {
		equalizer?.setBandLevel(band.toShort(), level)
	}
	fun setEqualizerEnabled(enabled: Boolean) {
		eqEnabled = enabled
		equalizer?.enabled = enabled
		// Master toggle for all effects
		bassBoost?.enabled = enabled
		virtualizer?.enabled = enabled
		reverb?.enabled = enabled
		if (!enabled) {
			try { bassBoost?.setStrength(0) } catch (_: Exception) {}
			try { virtualizer?.setStrength(0) } catch (_: Exception) {}
		} else {
			try { bassBoost?.setStrength(bassBoostStrength.toShort()) } catch (_: Exception) {}
			try { virtualizer?.setStrength(virtualizerStrength.toShort()) } catch (_: Exception) {}
			try { if (reverbPreset >= 0) reverb?.preset = reverbPreset.toShort() } catch (_: Exception) {}
		}
	}
	fun getEqualizerEnabled(): Boolean {
		return eqEnabled
	}
	fun setEqualizerPreset(preset: Int) {
		eqPreset = preset
		if (equalizer != null && preset >= 0 && preset < (equalizer?.numberOfPresets ?: 0)) {
			equalizer?.usePreset(preset.toShort())
		}
	}
	fun getEqualizerPreset(): Int {
		return eqPreset
	}
	fun setReverbPreset(preset: Int) {
		reverbPreset = preset
		reverb?.preset = preset.toShort()
	}
	fun getReverbPreset(): Int {
		return reverbPreset
	}
	fun setBassBoostStrength(strength: Int) {
		bassBoostStrength = strength
		bassBoost?.setStrength(strength.toShort())
	}
	fun getBassBoostStrength(): Int {
		return bassBoostStrength
	}
	fun setVirtualizerStrength(strength: Int) {
		virtualizerStrength = strength
		virtualizer?.setStrength(strength.toShort())
	}
	fun getVirtualizerStrength(): Int {
		return virtualizerStrength
	}

	fun getBandLevelsForPreset(preset: Int): List<Int> {
		val eq = equalizer ?: return emptyList()
		if (preset < 0 || preset >= eq.numberOfPresets) return emptyList()
		eq.usePreset(preset.toShort())
		val levels = mutableListOf<Int>()
		for (i in 0 until eq.numberOfBands) {
			levels.add(eq.getBandLevel(i.toShort()).toInt())
		}
		// Restore current preset after reading
		if (eqPreset >= 0 && eqPreset < eq.numberOfPresets) {
			eq.usePreset(eqPreset.toShort())
		}
		return levels
	}

	private fun updateMediaSessionState(isPlaying: Boolean) {
		val position = mediaPlayer?.currentPosition?.toLong() ?: 0L
		val duration = mediaPlayer?.duration?.toLong() ?: 0L
		val stateBuilder = PlaybackStateCompat.Builder()
			.setActions(
				PlaybackStateCompat.ACTION_PLAY or
				PlaybackStateCompat.ACTION_PAUSE or
				PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
				PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
				PlaybackStateCompat.ACTION_STOP or
				PlaybackStateCompat.ACTION_SEEK_TO
			)
			.setState(
				if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED,
				position,
				1.0f
			)
			.setBufferedPosition(duration)
		mediaSession.setPlaybackState(stateBuilder.build())
	}

	private fun sendFlutterAction(action: String) {
		// Send a custom event to Flutter via the eventSink
		val event = mapOf("action" to action)
		EventBridge.eventSink?.success(event)
	}

	private fun startPlaybackStateUpdates() {
		stopPlaybackStateUpdates()
		playbackStateUpdateRunnable = object : Runnable {
			override fun run() {
				updateMediaSessionState(mediaPlayer?.isPlaying == true)
				playbackStateUpdateHandler?.postDelayed(this, 1000)
			}
		}
		playbackStateUpdateHandler?.post(playbackStateUpdateRunnable!!)
	}

	private fun stopPlaybackStateUpdates() {
		playbackStateUpdateRunnable?.let { playbackStateUpdateHandler?.removeCallbacks(it) }
		playbackStateUpdateRunnable = null
	}

	fun getCurrentPlaybackInfo(): Map<String, Any>? {
		return try {
			val isPlaying = mediaPlayer?.isPlaying ?: false
			val position = mediaPlayer?.currentPosition ?: 0
			val duration = mediaPlayer?.duration ?: 0
			val state = if (isPlaying) "playing" else "paused"

			mapOf(
				"state" to state,
				"position" to position,
				"duration" to duration,
				"filePath" to (currentFilePath ?: ""),
				"playbackSpeed" to playbackSpeed,
				"equalizerEnabled" to eqEnabled,
				"equalizerPreset" to eqPreset,
				"reverbPreset" to reverbPreset,
				"bassBoostStrength" to bassBoostStrength,
				"virtualizerStrength" to virtualizerStrength
			)
		} catch (e: Exception) {
			Log.e("AudioPlayerService", "Error getting current playback info", e)
			null
		}
	}
} 