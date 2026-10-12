/*
 * SPDX-FileCopyrightText: 2026 Zesseth
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
#include <sailfishapp.h>
#include <QScopedPointer>
#include <QQuickView>
#include <QQmlContext>
#include <QtGui>
#include <QtQml>
#include "pricefetcher.h"
#include "settings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    Settings settings;
    PriceFetcher fetcher;
    fetcher.setResolution(settings.resolution());
    QObject::connect(&settings, &Settings::resolutionChanged, &fetcher, [&settings, &fetcher]() {
        fetcher.setResolution(settings.resolution());
    });

    view->rootContext()->setContextProperty(QStringLiteral("priceFetcher"), &fetcher);
    view->rootContext()->setContextProperty(QStringLiteral("appSettings"), &settings);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QStringLiteral(APP_VERSION));

    view->setSource(SailfishApp::pathTo("qml/harbour-sahkonseuranta.qml"));
    view->show();

    return app->exec();
}
