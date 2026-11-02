/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "livecaptionengine.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("klivecaptions"));
    app.setApplicationDisplayName(QStringLiteral("KLiveCaptions"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));

    LiveCaptionEngine engine;

    QQmlApplicationEngine qmlEngine;
    qmlEngine.rootContext()->setContextProperty(QStringLiteral("CaptionEngine"), &engine);
    qmlEngine.load(QUrl(QStringLiteral("qrc:/org/cesar/klivecaptions/qml/main.qml")));

    if (qmlEngine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
