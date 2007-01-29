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
package net.sf.jooreports.openoffice.converter.functional;

import java.io.IOException;

import net.sf.jooreports.converter.util.FileType;

public class SpreadsheetConversionTest extends AbstractFunctionalConversionTest {

	public void testOdsToXls() throws IOException {
		convertAndCheck("hello.ods", "xls", FileType.MSOFFICE);
	}

	public void testOdsToSxc() throws IOException {
		convertAndCheck("hello.ods", "sxc", FileType.SXC);
	}

	public void testXlsToOds() throws IOException {
		convertAndCheck("hello.xls", "ods", FileType.ODS);
	}
}
