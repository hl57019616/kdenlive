/***************************************************************************
 *   Copyright (C) 2017 by Nicolas Carion                                  *
 *   This file is part of Kdenlive. See www.kdenlive.org.                  *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) version 3 or any later version accepted by the       *
 *   membership of KDE e.V. (or its successor approved  by the membership  *
 *   of KDE e.V.), which shall act as a proxy defined in Section 14 of     *
 *   version 3 of the license.                                             *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ***************************************************************************/

#include "transitionstackview.hpp"
#include "assets/model/assetparametermodel.hpp"
#include "core.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QComboBox>
#include <QLabel>
#include <QDebug>
#include <klocalizedstring.h>


TransitionStackView::TransitionStackView(QWidget *parent)
    : AssetParameterView(parent)
{
}

void TransitionStackView::setModel(const std::shared_ptr<AssetParameterModel> &model, QPair<int, int> range, bool addSpacer)
{
    QHBoxLayout *lay = new QHBoxLayout;
    m_trackBox = new QComboBox(this);
    m_trackBox->addItem(i18n("Background"), 0);
    QMapIterator<int, QString> i(pCore->getVideoTrackNames());
    while (i.hasNext()) {
        i.next();
        m_trackBox->addItem(i.value(), i.key());
    }
    AssetParameterView::setModel(model, range, addSpacer);

    int aTrack = pCore->getCompositionATrack(m_model->getOwnerId().second);
    m_trackBox->setCurrentIndex(m_trackBox->findData(aTrack));
    QLabel *title = new QLabel(i18n("Composition track: "), this);
    lay->addWidget(title);
    lay->addWidget(m_trackBox);
    m_lay->insertLayout(0, lay);
    connect(m_trackBox, SIGNAL(currentIndexChanged(int)), this, SLOT(updateTrack(int)));
}

void TransitionStackView::updateTrack(int newTrack)
{
    qDebug()<<"// Update transitiino TRACK to: "<<m_trackBox->currentData().toInt();
    pCore->setCompositionATrack(m_model->getOwnerId().second, m_trackBox->currentData().toInt());
}