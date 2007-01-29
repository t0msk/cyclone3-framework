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

import net.sf.jooreports.converter.DocumentConverter;
import net.sf.jooreports.openoffice.converter.AbstractConverterTest;
import net.sf.jooreports.openoffice.converter.OpenOfficeDocumentConverter;

public abstract class AbstractFunctionalConversionTest extends AbstractConverterTest {

	private DocumentConverter documentConverter;

	protected void setUp() throws Exception {
		super.setUp();
		
		// use the default one for functional tests 
		documentConverter = new OpenOfficeDocumentConverter(getOpenOfficeConnection());
	}

	protected DocumentConverter getDocumentConverter() {
		return documentConverter;
	}
}
