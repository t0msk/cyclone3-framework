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

import java.io.File;
import java.io.IOException;

import junit.framework.TestCase;
import net.sf.jooreports.converter.BasicDocumentFormatRegistry;
import net.sf.jooreports.converter.DocumentConverter;
import net.sf.jooreports.converter.DocumentFamily;
import net.sf.jooreports.converter.DocumentFormat;
import net.sf.jooreports.converter.DocumentFormatRegistry;
import net.sf.jooreports.converter.util.FileType;
import net.sf.jooreports.converter.util.OpenOfficeTestContext;
import net.sf.jooreports.openoffice.connection.OpenOfficeConnection;

import org.apache.commons.io.FileUtils;

public abstract class AbstractConverterTest extends TestCase {

    private static final String TEST_RESOURCE_PATH = "src/test/resources";
    private static final int BYTE_ORDER_MARK_CHAR = 0xFEFF;

	private OpenOfficeConnection openOfficeConnection;
	private DocumentFormatRegistry documentFormatRegistry;
    private DocumentConverter documentConverter;

	protected void setUp() throws Exception {
		openOfficeConnection = OpenOfficeTestContext.getInstance().getOpenOfficeConnection();
		documentFormatRegistry = createTestDocumentFormatRegistry();
		documentConverter = new OpenOfficeDocumentConverter(openOfficeConnection, documentFormatRegistry);
	}

	private DocumentFormatRegistry createTestDocumentFormatRegistry() {
		// ODT to PDF is the only conversions needed by *unit* tests
		BasicDocumentFormatRegistry registry = new BasicDocumentFormatRegistry();
		
		DocumentFormat odt = new DocumentFormat("ODT", DocumentFamily.TEXT, "application/vnd.oasis.opendocument.text", "odt");
		registry.addDocumentFormat(odt);
		
		DocumentFormat pdf = new DocumentFormat("PDF", DocumentFamily.TEXT, "application/pdf", "pdf");
		pdf.setExportFilter(DocumentFamily.TEXT, "writer_pdf_Export");
		registry.addDocumentFormat(pdf);
		
		return registry;
	}

	protected OpenOfficeConnection getOpenOfficeConnection() {
		return openOfficeConnection;
	}

	public DocumentFormatRegistry getDocumentFormatRegistry() {
		return documentFormatRegistry;
	}

	protected DocumentConverter getDocumentConverter() {
		return documentConverter;
	}
    
    protected File createTempFile(String extension) throws IOException {
        File tempFile = File.createTempFile("document", "."+ extension);
        tempFile.deleteOnExit();
        return tempFile;
    }

    protected File getTestFile(String fileName) {
    	return new File(TEST_RESOURCE_PATH, fileName);
    }

    protected File convertAndCheck(String fileName, String extension, FileType fileType) throws IOException {
    	File inputFile = getTestFile(fileName);
        File outputFile = createTempFile(extension);
        getDocumentConverter().convert(inputFile, outputFile);
        checkOutputFile(outputFile, fileType);
        return outputFile;
    }

    protected void checkOutputFile(File outputFile, FileType fileType) throws IOException {
        assertTrue("file not created", outputFile.isFile());
        assertFalse("file is empty", outputFile.length() == 0);
        assertTrue("file not of type " + fileType.getName(), fileType.matches(outputFile));    	
    }

	protected String readTextContent(File file) throws IOException {
	    String content = FileUtils.readFileToString(file, "UTF-8");
	    return stripByteOrderMarkChar(content).trim();
	}

	protected String stripByteOrderMarkChar(String content) {        
	    if (content.length() > 0 && content.charAt(0) == BYTE_ORDER_MARK_CHAR) {
	        return content.substring(1).trim();
	    }
	    return content;
	}
}
