/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "livecaptionengine.h"

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("klivecaptions"));
    app.setApplicationDisplayName(QStringLiteral("KLiveCaptions"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));

    // Golden Gate parity: the application inherits the Plasma desktop style so
    // menus, tooltips and combo boxes match the rest of the CachyOS.UI
    // ecosystem instead of the raw Basic style.
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Subtítulos en tiempo real del audio del sistema"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption screenshotOpt(QStringLiteral("screenshot"),
                                     QStringLiteral("Capture window screenshot and exit"),
                                     QStringLiteral("path"));
    parser.addOption(screenshotOpt);
    parser.process(app);

    LiveCaptionEngine engine;

    QQmlApplicationEngine qmlEngine;
    // The CachyOS.UI design system (Liquid Glass) is installed system wide or
    // in the user prefix.
    qmlEngine.addImportPath(QStringLiteral("/home/cesar/.local/lib/qt6/qml"));
    qmlEngine.rootContext()->setContextProperty(QStringLiteral("CaptionEngine"), &engine);
    qmlEngine.load(QUrl(QStringLiteral("qrc:/org/cesar/klivecaptions/qml/main.qml")));

    if (qmlEngine.rootObjects().isEmpty()) {
        return -1;
    }

    if (parser.isSet(screenshotOpt)) {
        if (auto *win = qobject_cast<QQuickWindow *>(qmlEngine.rootObjects().constFirst())) {
            const QString outPath = parser.value(screenshotOpt);
            QTimer::singleShot(350, win, [win, outPath, &app]() {
                const QImage img = win->grabWindow();
                img.save(outPath);
                app.quit();
            });
        }
    }

    return app.exec();
}
