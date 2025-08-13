package com.mediaplayer.music.player.videoplayer

import io.flutter.plugin.common.EventChannel

object EventBridge {
	@Volatile
	var eventSink: EventChannel.EventSink? = null
} 