//
// JOOConverter - The Open Source Java/OpenOffice Document Converter
// Copyright (C) 2004-2006 - Mirko Nasato <mirko@artofsolving.com>
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// http://www.gnu.org/copyleft/lesser.html
//
package net.sf.jooreports.converter.util;

import java.net.ConnectException;

import net.sf.jooreports.openoffice.connection.OpenOfficeConnection;
import net.sf.jooreports.openoffice.connection.SocketOpenOfficeConnection;

public class OpenOfficeTestContext {

    private static final OpenOfficeTestContext instance = new OpenOfficeTestContext();

    private OpenOfficeConnection openOfficeConnection;

    private OpenOfficeTestContext() {
	    openOfficeConnection = new SocketOpenOfficeConnection();
	    try {
			openOfficeConnection.connect();
		} catch (ConnectException connectException) {
			throw new RuntimeException(connectException);
		}

	    Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				openOfficeConnection.disconnect();
			}
		});
    }

    public OpenOfficeConnection getOpenOfficeConnection() {
		return openOfficeConnection;
	}

    public static OpenOfficeTestContext getInstance() {
        return instance;
    }
}
