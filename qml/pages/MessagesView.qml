/*
 * Copyright (C) 2012-2015 Jolla Ltd.
 *
 * The code in this file is distributed under multiple licenses, and as such,
 * may be used under any one of the following licenses:
 *
 *   - GNU General Public License as published by the Free Software Foundation;
 *     either version 2 of the License (see LICENSE.GPLv2 in the root directory
 *     for full terms), or (at your option) any later version.
 *   - GNU Lesser General Public License as published by the Free Software
 *     Foundation; either version 2.1 of the License (see LICENSE.LGPLv21 in the
 *     root directory for full terms), or (at your option) any later version.
 *   - Alternatively, if you have a commercial license agreement with Jolla Ltd,
 *     you may use the code under the terms of that license instead.
 *
 * You can visit <https://sailfishos.org/legal/> for more information
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.commhistory 1.0
import "../delegates"

SilicaListView {
    id: messagesView

    verticalLayoutDirection: ListView.BottomToTop
    // Necessary to avoid resetting focus every time a row is added, which breaks text input
    currentIndex: -1
    quickScroll: false

    PullDownMenu {
        MenuItem {
            text: qsTr("Load More")
            onClicked: console.log("Load more messages!")
        }
    }

    delegate: Item {
        id: wrapper

        // This would normally be previousSection, but our model's order is inverted.
        property bool sectionBoundary: (ListView.nextSection != "" && ListView.nextSection !== ListView.section)
                                        || model.index === messagesView.count - 1
        property Item section

        height: loader.y + loader.height
        width: parent.width

        ListView.onRemove: loader.item.animateRemoval(wrapper)

        Loader {
            id: loader
            y: section ? section.y + section.height : 0
            width: parent.width
            sourceComponent: messageDelegate
        }

        onSectionBoundaryChanged: {
            if (sectionBoundary) {
                section = sectionHeader.createObject(wrapper, { 'modelData': model })
            } else {
                section.destroy()
                section = null
            }
        }

        Component {
            id: messageDelegate

            Message { 
                modelData: model
            }
        }
    }

    section.property: "localUid"

    Component {
        id: sectionHeader

        Row {
            id: header
            y: Theme.paddingMedium
            x: parent ? (parent.width - width) / 2 : 0
            height: text.implicitHeight + Theme.paddingSmall
            spacing: Theme.paddingMedium

            Label {
                id: text
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: MessageModel.group ? qsTr("Group: "+MessageModel.peerName) : MessageModel.peerName
            }
        }
    }

    function remove(contentItem) {
        contentItem.remorseAction(qsTr("Deleting"),
            function() {
                console.log("Delete message: "+contentItem.modelData.display.id)
                MessageModel.remove(contentItem.modelData.index)
            })
    }

    function copy(contentItem) {
        Backend.copyToClipboard(contentItem.modelData.display.message)
    }

    Component {
        id: messageContextMenu

        ContextMenu {
            id: menu

            width: parent ? parent.width : Screen.width

            MenuItem {
                visible: menu.parent && menu.parent.hasText
                text: qsTr("Copy")
                onClicked: copy(menu.parent)
            }
            MenuItem {
                text: qsTr("Delete")
                onClicked: remove(menu.parent)
            }
        }
    }


    RemorsePopup { id: remorse }

    PushUpMenu {
        MenuItem {
            text: qsTr("Verify Identity")
            enabled: MessageModel.peerIdentity.length > 0
            onClicked: pageStack.push(Qt.resolvedUrl("VerifyIdentity.qml"))
        }
        MenuItem {
            text: qsTr("Reset Secure Session")
            enabled: MessageModel.peerIdentity.length > 0
            onClicked: {
                remorse.execute(qsTr("Resetting secure session"),
                    function() {
                        console.log("Resetting secure session: "+MessageModel.peerTel)
                        Backend.endSession(MessageModel.peerTel)
                    })
            }
        }
    }

    VerticalScrollDecorator {}
}

