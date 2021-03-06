import QtQuick.Controls 2.4
import Kdenlive.Controls 1.0
import QtQuick 2.11

    // Monitor ruler
Rectangle {
    id: ruler
    color: activePalette.base
    property bool containsMouse: rulerMouseArea.containsMouse
    property bool seekingFinished : controller.seekFinished
    // The width of the visible part
    property double rulerZoomWidth: root.zoomFactor * width
    // The pixel offset
    property double rulerZoomOffset: root.zoomStart * width / root.zoomFactor
    Rectangle {
        color: activePalette.light
        width: parent.width
        height: 1
    }

    function zoomInRuler(xPos)
    {
        root.showZoomBar = true
        var middle = xPos / rulerMouseArea.width / 1.2
        root.zoomFactor = Math.min(1, root.zoomFactor / 1.2)
        var startPos = Math.max(0, middle - root.zoomFactor / 2)
        if (startPos + root.zoomFactor > 1) {
            startPos = 1 - root.zoomFactor
        }
        root.zoomStart = startPos
        zoomBar.x = root.zoomStart * zoomHandleContainer.width
        zoomBar.width = root.zoomFactor * zoomHandleContainer.width
    }
    
    function zoomOutRuler(xPos)
    {
        root.zoomFactor = Math.min(1, root.zoomFactor * 1.2)
        if (root.zoomFactor == 1) {
            root.zoomStart = 0
            root.showZoomBar = false
        } else {
            var middle = root.zoomStart + root.zoomFactor / 2
            middle = Math.max(0, middle - root.zoomFactor / 2)
            if (middle + root.zoomFactor > 1) {
                middle = 1 - root.zoomFactor
            }
            root.zoomStart = middle
        }
        zoomBar.x = root.zoomStart * zoomHandleContainer.width
        zoomBar.width = root.zoomFactor * zoomHandleContainer.width
    }

    // Zoom bar container
    Rectangle {
        height: root.baseUnit
        color: activePalette.base
        visible: root.showZoomBar
        onVisibleChanged: {
            root.zoomOffset = visible ? height : 0
        }
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        Item {
            id: zoomHandleContainer
            property int previousX: 0
            property int previousWidth: zoomHandleContainer.width
            anchors.fill: parent
            anchors.margins: 3
            Rectangle {
                id: zoomBar
                radius: height / 2
                color: (zoomArea.containsMouse ||  zoomArea.pressed) ? activePalette.highlight : activePalette.text
                height: parent.height
                width: parent.width
                MouseArea {
                    id: zoomArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    drag.target: zoomBar
                    drag.axis: Drag.XAxis
                    drag.smoothed: false
                    drag.minimumX: 0
                    drag.maximumX: zoomHandleContainer.width - zoomBar.width
                    onPositionChanged: {
                        root.zoomStart = zoomBar.x / zoomHandleContainer.width
                    }
                    onDoubleClicked: {
                        if (zoomBar.x == 0 && zoomBar.width == zoomHandleContainer.width) {
                            // Restore previous pos
                            zoomBar.width = zoomHandleContainer.previousWidth
                            zoomBar.x = zoomHandleContainer.previousX
                            root.zoomStart = zoomBar.x / zoomHandleContainer.width
                            root.zoomFactor = zoomBar.width / zoomHandleContainer.width
                        } else {
                            zoomHandleContainer.previousWidth = zoomBar.width
                            zoomHandleContainer.previousX = zoomBar.x
                            zoomBar.x = 0
                            zoomBar.width = zoomHandleContainer.width
                            root.zoomStart = 0
                            root.zoomFactor = 1
                        }
                    }
                    onWheel: {
                        if (wheel.modifiers & Qt.ControlModifier) {
                            if (wheel.angleDelta.y < 0) {
                                // zoom out
                                zoomOutRuler(wheel.x)
                            } else {
                                // zoom in
                                zoomInRuler(wheel.x)
                            }
                        }
                    }
                }
            }
            MouseArea {
                id: zoomStart
                anchors.left: zoomBar.left
                anchors.leftMargin: - root.baseUnit / 2
                anchors.bottom: zoomBar.bottom
                width: root.baseUnit
                height: zoomBar.height
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: {
                    anchors.left = undefined
                }
                onReleased: {
                    anchors.left = zoomBar.left
                }
                onPositionChanged: {
                    if (mouse.buttons === Qt.LeftButton) {
                        var updatedPos = Math.max(0, x + mouseX + root.baseUnit / 2)
                        updatedPos = Math.min(updatedPos, zoomBar.x + zoomBar.width - root.baseUnit / 2)
                        zoomBar.width = zoomBar.x + zoomBar.width - updatedPos
                        zoomBar.x = updatedPos
                        root.zoomStart = updatedPos / zoomHandleContainer.width
                        root.zoomFactor = zoomBar.width / zoomHandleContainer.width
                    }
                }
            }
            MouseArea {
                id: zoomEnd
                anchors.left: zoomBar.right
                anchors.leftMargin: - root.baseUnit / 2
                anchors.bottom: zoomBar.bottom
                width: root.baseUnit
                height: zoomBar.height
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: {
                    anchors.left = undefined
                }
                onReleased: {
                    anchors.left = zoomBar.right
                }
                onPositionChanged: {
                    if (mouse.buttons === Qt.LeftButton) {
                        var updatedPos = Math.min(zoomHandleContainer.width, x + mouseX + root.baseUnit / 2)
                        updatedPos = Math.max(updatedPos, zoomBar.x + root.baseUnit / 2)
                        zoomBar.width = updatedPos - zoomBar.x
                        root.zoomFactor = zoomBar.width / zoomHandleContainer.width
                    }
                }
            }
        }
        ToolTip {
            visible: zoomArea.containsMouse
            delay: 1000
            timeout: 5000
            background: Rectangle {
                color: activePalette.alternateBase
                border.color: activePalette.light
            }
            contentItem: Label {
                color: activePalette.text
                font: fixedFont
                text: controller.toTimecode((root.duration + 1 )* root.zoomFactor)
            }
        }
    }
    onSeekingFinishedChanged : {
        playhead.opacity = seekingFinished ? 1 : 0.5
    }

    onRulerZoomWidthChanged: {
        updateRuler()
    }

    Timer {
        id: zoneToolTipTimer
        interval: 3000; running: false;
    }
    function forceRepaint()
    {
        ruler.color = activePalette.base
        // Enforce repaint
        rulerTicks.model = 0
        rulerTicks.model = ruler.rulerZoomWidth / frameSize + 2
        playhead.fillColor = activePalette.windowText
    }

    function updateRuler()
    {
        var projectFps = controller.fps()
        root.timeScale = ruler.width / root.duration / root.zoomFactor
        var displayedLength = root.duration * root.zoomFactor / projectFps;
        if (displayedLength < 3 ) {
            // 1 frame tick
            root.frameSize = root.timeScale
        } else if (displayedLength < 30) {
            // 1 second tick
            frameSize = projectFps * root.timeScale
        } else if (displayedLength < 150) {
            // 5 second tick
            frameSize = 5 * projectFps * root.timeScale
        } else if (displayedLength < 300) {
            // 10 second tick
            frameSize = 10 * projectFps * root.timeScale
        } else if (displayedLength < 900) {
            // 30 second tick
            frameSize = 30 * projectFps * root.timeScale
        } else if (displayedLength < 1800) {
            // 1 min. tick
            frameSize = 60 * projectFps * root.timeScale
        } else if (displayedLength < 9000) {
            // 5 min tick
            frameSize = 300 * projectFps * root.timeScale
        } else if (displayedLength < 18000) {
            // 10 min tick
            frameSize = 600 * projectFps * root.timeScale
        } else {
            // 30 min tick
            frameSize = 18000 * projectFps * root.timeScale
        }
    }

    // Ruler zone
    Rectangle {
        id: zone
        visible: controller.zoneOut > controller.zoneIn
        color: activePalette.highlight
        x: controller.zoneIn * root.timeScale / root.zoomFactor - ruler.rulerZoomOffset
        width: (controller.zoneOut - controller.zoneIn) * root.timeScale / root.zoomFactor
        anchors.bottom: parent.bottom
        height: ruler.height / 2
        opacity: 0.8
        onXChanged: zoneToolTipTimer.start()
        onWidthChanged: zoneToolTipTimer.start()
    }

    // frame ticks
    Repeater {
        id: rulerTicks
        model: ruler.width / frameSize + 2
        Rectangle {
            x: index * frameSize - (ruler.rulerZoomOffset % frameSize)
            anchors.bottom: ruler.bottom
            height: (index % 5) ? ruler.height / 4 : ruler.height / 2
            width: 1
            color: activePalette.windowText
            opacity: 0.5
        }
    }
    MouseArea {
        id: rulerMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPressed: {
            if (mouse.buttons === Qt.LeftButton) {
                var pos = Math.max(mouseX, 0)
                controller.position = Math.min((pos + ruler.rulerZoomOffset)*root.zoomFactor / root.timeScale, root.duration);
            }
        }
        onPositionChanged: {
            if (mouse.buttons === Qt.LeftButton) {
                var pos = Math.max(mouseX, 0)
                root.mouseRulerPos = pos
                if (pressed) {
                    controller.position = Math.min((pos + ruler.rulerZoomOffset)*root.zoomFactor / root.timeScale, root.duration);
                }
            }
        }
        onWheel: {
            if (wheel.modifiers & Qt.ControlModifier) {
                if (wheel.angleDelta.y < 0) {
                    // zoom out
                    zoomOutRuler(wheel.x)
                } else {
                    // zoom in
                    zoomInRuler(wheel.x)
                }
            }
        }
    }
    // Zone duration indicator
    Rectangle {
        visible: inZoneMarker.visible || zoneToolTipTimer.running
        width: inLabel.contentWidth + 4
        height: inLabel.contentHeight + 2
        property int centerPos: zone.x + zone.width / 2 - inLabel.contentWidth / 2
        x: centerPos < 0 ? 0 : centerPos > ruler.width - inLabel.contentWidth ? ruler.width - inLabel.contentWidth - 2 : centerPos
        color: activePalette.alternateBase
        anchors.bottom: ruler.top
        Label {
            id: inLabel
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            text: trimInMouseArea.containsMouse || trimInMouseArea.pressed ? controller.toTimecode(controller.zoneIn) + '>' + controller.toTimecode(controller.zoneOut - controller.zoneIn) : trimOutMouseArea.containsMouse || trimOutMouseArea.pressed ? controller.toTimecode(controller.zoneOut - controller.zoneIn) + '<' + controller.toTimecode(controller.zoneOut) : controller.toTimecode(controller.zoneOut - controller.zoneIn)
            font: fixedFont
            color: activePalette.text
        }
    }
    // monitor zone
    Rectangle {
        id: inZoneMarker
        x: controller.zoneIn * root.timeScale/ root.zoomFactor - ruler.rulerZoomOffset
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        width: 1
        color: activePalette.highlight
        visible: controller.zoneOut > controller.zoneIn && (rulerMouseArea.containsMouse || trimOutMouseArea.containsMouse || trimOutMouseArea.pressed || trimInMouseArea.containsMouse)
    }
    Rectangle {
        x: controller.zoneOut * root.timeScale/ root.zoomFactor - ruler.rulerZoomOffset
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        width: 1
        color: activePalette.highlight
        visible: inZoneMarker.visible
    }
    TimelinePlayhead {
        id: playhead
        visible: controller.position > -1
        height: ruler.height * 0.5
        width: ruler.height * 1
        opacity: 1
        anchors.top: ruler.top
        fillColor: activePalette.windowText
        x: controller.position * root.timeScale / root.zoomFactor - (width / 2) - ruler.rulerZoomOffset
    }
    Rectangle {
        id: trimIn
        x: zone.x - root.baseUnit / 3
        y: zone.y
        height: zone.height
        width: root.baseUnit * .8
        color: 'lawngreen'
        opacity: trimInMouseArea.containsMouse || trimInMouseArea.drag.active ? 0.5 : 0
        Drag.active: trimInMouseArea.drag.active
        Drag.proposedAction: Qt.MoveAction
        MouseArea {
            id: trimInMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.smoothed: false
            drag.minimumX: 0
            drag.maximumX: ruler.width
            onPressed: {
                controller.startZoneMove()
            }
            onReleased: {
                controller.endZoneMove()
            }
            onPositionChanged: {
                if (mouse.buttons === Qt.LeftButton) {
                    controller.zoneIn = Math.round((trimIn.x + ruler.rulerZoomOffset) / root.timeScale)
                }
            }
        }
    }
    Rectangle {
        id: trimOut
        width: root.baseUnit * .8
        x: zone.x + zone.width - (width * .7)
        y: zone.y
        height: zone.height
        color: 'darkred'
        opacity: trimOutMouseArea.containsMouse || trimOutMouseArea.drag.active ? 0.5 : 0
        Drag.active: trimOutMouseArea.drag.active
        Drag.proposedAction: Qt.MoveAction
        MouseArea {
            id: trimOutMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.smoothed: false
            drag.minimumX: 0
            drag.maximumX: ruler.width - trimOut.width
            onPressed: {
                controller.startZoneMove()
            }
            onReleased: {
                controller.endZoneMove()
            }
            onPositionChanged: {
                if (mouse.buttons === Qt.LeftButton) {
                    controller.zoneOut = Math.round((trimOut.x + trimOut.width + ruler.rulerZoomOffset) / root.timeScale)
                }
            }
        }
    }

    // markers
    Repeater {
        model: markersModel
        delegate:
        Item {
            anchors.fill: parent
            Rectangle {
                id: markerBase
                width: 1
                height: parent.height
                x: (model.frame) * root.timeScale - ruler.rulerZoomOffset;
                color: model.color
            }
            Rectangle {
                visible: !rulerMouseArea.pressed && (guideArea.containsMouse || (rulerMouseArea.containsMouse && Math.abs(rulerMouseArea.mouseX - markerBase.x) < 4))
                opacity: 0.7
                property int guidePos: markerBase.x - mlabel.contentWidth / 2
                x: guidePos < 0 ? 0 : (guidePos > (parent.width - mlabel.contentWidth) ? parent.width - mlabel.contentWidth : guidePos)
                radius: 2
                width: mlabel.contentWidth
                height: mlabel.contentHeight * .8
                anchors {
                    bottom: parent.top
                }
                color: model.color
                Text {
                    id: mlabel
                    text: model.comment
                    font.pixelSize: root.baseUnit
                    verticalAlignment: Text.AlignVCenter
                    anchors {
                        fill: parent
                    }
                    color: 'white'
                }
                MouseArea {
                    z: 10
                    id: guideArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    //onDoubleClicked: timeline.editMarker(clipRoot.binId, model.frame)
                    onClicked: {
                        controller.position = model.frame
                    }
                }
            }
        }
    }
}

