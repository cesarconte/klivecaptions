/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "livecaptionengine.h"

#include <LayerShellQt/Window>

#include <QGuiApplication>
#include <QMargins>
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

    if (auto *win = qobject_cast<QQuickWindow *>(qmlEngine.rootObjects().first())) {
        if (auto *layerWin = LayerShellQt::Window::get(win)) {
            layerWin->setLayer(LayerShellQt::Window::LayerOverlay);
            layerWin->setAnchors(LayerShellQt::Window::AnchorBottom);
            layerWin->setMargins(QMargins(0, 0, 0, 48));
            layerWin->setExclusiveZone(0);
            layerWin->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
            layerWin->setScope(QStringLiteral("klivecaptions"));
        }
    }

    return app.exec();
}
