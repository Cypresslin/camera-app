/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: optionsOverlay

    property list<ListModel> options
    property bool valueSelectorOpened: optionValueSelector.caller != null

    function closeValueSelector() {
        optionValueSelector.hide();
        advancedOptionsToggle.selected = false;
    }

    height: optionsGrid.height + optionsGrid.rowSpacing + (advancedOptionsToggle.selected ?  advancedOptions.height : 0)

    Grid {
        id: optionsGrid
        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        columns: 3
        columnSpacing: units.gu(9.5)
        rowSpacing: units.gu(3)

        Repeater {
            model: optionsOverlay.options
            delegate: OptionButton {
                id: optionButton
                model: modelData
                onClicked: optionValueSelector.toggle(model, optionButton)
                enabled: model.available && (!optionValueSelector.caller || optionValueSelector.caller == optionButton)
                opacity: enabled ? 1.0 : 0.05
                Behavior on opacity {UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration}}
            }
        }
    }

    ListView {
        id: optionValueSelector
        objectName: "optionValueSelector"

        height: Math.min( contentHeight, parent.height )
        snapMode: ListView.SnapToItem
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds

        property OptionButton caller

        function toggle(model, callerButton) {
            if (optionValueSelectorVisible && optionValueSelector.model === model) {
                hide();
            } else {
                show(model, callerButton);
            }
        }

        function show(model, callerButton) {
            optionValueSelector.caller = callerButton;
            optionValueSelector.model = model;
            alignWith(callerButton);
            optionValueSelectorVisible = true;

        }

        function hide() {
            optionValueSelectorVisible = false;
            optionValueSelector.caller = null;
        }

        function alignWith(item) {
            if(model) {
                forceLayout();
                width = contentItem.childrenRect.width;
            }
            // horizontally center optionValueSelector with the center of item
            // if there is enough space to do so, that is as long as optionValueSelector
            // does not get cropped by the edge of the screen
            var itemX = parent.mapFromItem(item, 0, 0).x;
            var centeredX = itemX + item.width / 2.0 - width / 2.0;
            var margin = units.gu(1);

            if (centeredX < margin) {
                x = itemX;
            } else if (centeredX + width > item.parent.width - margin) {
                x = itemX + item.width - width;
            } else {
                x = centeredX;
            }

            // vertically position the options above the caller button
            y = Qt.binding(function() { return optionsGrid.y + item.y - height - units.gu(2) });
        }

        visible: opacity !== 0.0
        onVisibleChanged: if (!visible) model = null;
        opacity: optionValueSelectorVisible ? 1.0 : 0.0
        Behavior on opacity {UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration}}

        delegate: OptionValueButton {
            anchors.left: optionValueSelector.left
            columnWidth: optionValueSelector.width

            label: (model && model.label) ? i18n.tr(model.label) : ""
            iconName: (model && model.icon) ? model.icon : ""
            selected: optionValueSelector.model.selectedIndex == index

            isLast: index === optionValueSelector.count - 1
            onClicked: {
                if (optionValueSelector.model.setSettingProperty) {
                    optionValueSelector.model.setSettingProperty(optionValueSelector.model.get(index).value);
                } else {
                    settings[optionValueSelector.model.settingsProperty] = optionValueSelector.model.get(index).value;
                }
            }
        }
    }

    OptionValueButton {
        id:advancedOptionsToggle
        anchors.right: optionsOverlay.right
        anchors.bottom: optionsOverlay.bottom
        iconName:  "settings"
        isLast: true
        onClicked: {
            selected = !selected;
        }
    }

    AdvancedOptions {
        id:advancedOptions
        anchors.top :optionsGrid.bottom
        anchors.topMargin: units.gu(4)
    }
}
