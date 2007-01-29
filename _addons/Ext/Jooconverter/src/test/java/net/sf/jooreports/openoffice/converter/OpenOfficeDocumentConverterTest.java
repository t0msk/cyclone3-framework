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
package net.sf.jooreports.openoffice.converter;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import net.sf.jooreports.converter.DocumentFamily;
import net.sf.jooreports.converter.DocumentFormat;
import net.sf.jooreports.converter.DocumentFormatRegistry;
import net.sf.jooreports.converter.XmlDocumentFormatRegistry;
import net.sf.jooreports.openoffice.connection.OpenOfficeException;

import org.apache.commons.io.output.ByteArrayOutputStream;

public class OpenOfficeDocumentConverterTest extends AbstractConverterTest {

	public void testConversionWithEmulatedStreams() throws IOException {
		DocumentFormatRegistry registry = new XmlDocumentFormatRegistry();
		
		InputStream inputStream = new FileInputStream(getTestFile("hello.odt"));
		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
		getDocumentConverter().convert(inputStream, registry.getFormatByFileExtension("odt"), outputStream, registry.getFormatByFileExtension("txt"));
		inputStream.close();
		assertEquals("output content", "Hello from an OpenDocument Text!", stripByteOrderMarkChar(outputStream.toString("UTF-8")));
	}

	public void testNullArgumentWithStreams() {
		DocumentFormat inputFormat = new DocumentFormat("XYZ", "application/xyz", "xyz");
		DocumentFormat outputFormat = new DocumentFormat("ABC", "application/abc", "abc");
		
		InputStream inputStream = new ByteArrayInputStream(new byte[0]);
		OutputStream outputStream = new ByteArrayOutputStream();
		
		try {
			getDocumentConverter().convert(null, inputFormat, outputStream, outputFormat);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("inputStream is null", argumentException.getMessage());
		}

		try {
			getDocumentConverter().convert(inputStream, null, outputStream, outputFormat);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("inputFormat is null", argumentException.getMessage());
		}

		try {
			getDocumentConverter().convert(inputStream, inputFormat, null, outputFormat);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("outputStream is null", argumentException.getMessage());
		}

		try {
			getDocumentConverter().convert(inputStream, inputFormat, outputStream, null);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("outputFormat is null", argumentException.getMessage());
		}
	}

	public void testNullArgumentWithFiles() throws IOException {
		try {
			getDocumentConverter().convert(null, new File("unused"));
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("inputFile is null", argumentException.getMessage());
		}

		try {
			getDocumentConverter().convert(new File("unused"), null);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertEquals("outputFile is null", argumentException.getMessage());
		}
	}

	public void testNoSuchInputFile() throws IOException {
		try {
			getDocumentConverter().convert(new File("no-such-file.odt"), new File("unused"));
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertTrue(argumentException.getMessage().startsWith("inputFile doesn't exist"));
		}
	}

	public void testUnknownInputFileFormat() throws IOException {
		try {
			getDocumentConverter().convert(getTestFile("unknown-type.xyz"), new File("unused"));
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertTrue(argumentException.getMessage().startsWith("unknown document format"));
		}
	}

	public void testExportOnlyFormatAsInput() throws IOException {
		DocumentFormat inputFormat = new DocumentFormat("XYZ", "application/xyz", "xyz");
		DocumentFormat outputFormat = new DocumentFormat("ABC", "application/abc", "abc");
		try {
			getDocumentConverter().convert(getTestFile("unknown-type.xyz"), inputFormat, new File("unused"), outputFormat);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertTrue(argumentException.getMessage().startsWith("unsupported input format"));
		}
	}

	public void testUnsupportedConversion() throws IOException {
		DocumentFormat inputFormat = new DocumentFormat("XYZ", DocumentFamily.TEXT, "application/xyz", "xyz");
		DocumentFormat outputFormat = new DocumentFormat("ABC", "application/abc", "abc");
		try {
			getDocumentConverter().convert(getTestFile("unknown-type.xyz"), inputFormat, new File("unused"), outputFormat);
			fail("should throw exception");
		} catch (IllegalArgumentException argumentException) {
			assertTrue(argumentException.getMessage().startsWith("unsupported conversion"));
		}
	}

	public void testCorruptedInputFile() throws IOException {
		File inputFile = getTestFile("invalid.odt");
		try {
			getDocumentConverter().convert(inputFile, createTempFile("pdf"));
			fail("should have detected that the input file was invalid");
		} catch (OpenOfficeException openOfficeException) {
			assertTrue(openOfficeException.getMessage().startsWith("conversion failed"));
		}
	}
}
