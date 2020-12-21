/*
 * Copyright (C) 2020 John Neffenger
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
package org.status6.hello.javafx;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

/**
 * A JavaFX application that prints "Hello World!" to standard output when its
 * button is pressed.
 */
public class Hello extends Application {

    /**
     * A method for unit testing.
     *
     * @return <code>true</code>
     */
    static boolean isTrue() {
        return true;
    }

    @Override
    public void start(Stage stage) {
        Button button = new Button("Say Hello World!");
        button.setOnAction(e -> System.out.println("Hello World!"));
        StackPane root = new StackPane(button);
        Scene scene = new Scene(root);

        stage.setScene(scene);
        stage.setTitle("Hello JavaFX");
        stage.setWidth(800);
        stage.setHeight(600);
        stage.show();
    }

    /**
     * The entry point for this application.
     *
     * @param args command-line arguments
     */
    public static void main(String[] args) {
        launch(args);
    }
}
