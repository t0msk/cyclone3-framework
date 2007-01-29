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

public class PresentationConversionTest extends AbstractFunctionalConversionTest {

	public void testOdpToPpt() throws IOException {
		convertAndCheck("hello.odp", "ppt", FileType.MSOFFICE);
	}

	public void testOdpToSxi() throws IOException {
		convertAndCheck("hello.odp", "sxi", FileType.SXI);
	}

	public void testOdpToSwf() throws IOException {
		convertAndCheck("hello.odp", "swf", FileType.SWF);
	}

	public void testPptToOdp() throws IOException {
		convertAndCheck("hello.ppt", "odp", FileType.ODP);
	}
}
