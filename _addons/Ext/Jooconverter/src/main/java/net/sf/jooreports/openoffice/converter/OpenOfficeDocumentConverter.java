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
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import net.sf.jooreports.converter.DocumentConverter;
import net.sf.jooreports.converter.DocumentFormat;
import net.sf.jooreports.converter.DocumentFormatRegistry;
import net.sf.jooreports.openoffice.connection.OpenOfficeConnection;
import net.sf.jooreports.openoffice.connection.OpenOfficeException;

import org.apache.commons.io.IOUtils;

import com.sun.star.beans.PropertyValue;
import com.sun.star.frame.XComponentLoader;
import com.sun.star.frame.XStorable;
import com.sun.star.lang.XComponent;
import com.sun.star.ucb.XFileIdentifierConverter;
import com.sun.star.uno.UnoRuntime;

/**
 * Default file-based {@link DocumentConverter} implementation.
 * <p>
 * This implementation passes document data to and from the OpenOffice.org
 * service as file URLs.
 * <p>
 * File-based conversions are faster than stream-based ones (provided by
 * {@link StreamOpenOfficeDocumentConverter}) but they require the
 * OpenOffice.org service to be running locally and have the correct
 * permissions to the files.
 * 
 * @see StreamOpenOfficeDocumentConverter
 */
public class OpenOfficeDocumentConverter extends AbstractOpenOfficeDocumentConverter {

	public OpenOfficeDocumentConverter(OpenOfficeConnection connection) {
		super(connection);
	}

	public OpenOfficeDocumentConverter(OpenOfficeConnection connection, DocumentFormatRegistry formatRegistry) {
		super(connection, formatRegistry);
	}

	/**
	 * In this file-based implementation, streams are emulated using temporary files.
	 */
	protected void convertInternal(InputStream inputStream, DocumentFormat inputFormat, OutputStream outputStream, DocumentFormat outputFormat) {
		File inputFile = null;
		File outputFile = null;
		try {
			inputFile = File.createTempFile("document", "." + inputFormat.getFileExtension());
			OutputStream inputFileStream = null;
			try {
				inputFileStream = new FileOutputStream(inputFile);
				IOUtils.copy(inputStream, inputFileStream);
			} finally {
				IOUtils.closeQuietly(inputFileStream);
			}
			
			outputFile = File.createTempFile("document", "." + outputFormat.getFileExtension());
			convert(inputFile, inputFormat, outputFile, outputFormat);
			InputStream outputFileStream = null;
			try {
				outputFileStream = new FileInputStream(outputFile);
				IOUtils.copy(outputFileStream, outputStream);
			} finally {
				IOUtils.closeQuietly(outputFileStream);
			}
		} catch (IOException ioException) {
			throw new OpenOfficeException("conversion failed", ioException);
		} finally {
			if (inputFile != null) {
				inputFile.delete();
			}
			if (outputFile != null) {
				outputFile.delete();
			}
		}
	}

	protected void convertInternal(File inputFile, DocumentFormat inputFormat, File outputFile, DocumentFormat outputFormat) {
		synchronized (openOfficeConnection) {
			XFileIdentifierConverter fileContentProvider = openOfficeConnection.getFileContentProvider();
			String inputUrl = fileContentProvider.getFileURLFromSystemPath("", inputFile.getAbsolutePath());
			String outputUrl = fileContentProvider.getFileURLFromSystemPath("", outputFile.getAbsolutePath());
			PropertyValue[] exportProperties = new PropertyValue[] {
				property("FilterName", outputFormat.getExportFilter(inputFormat.getFamily())),
				property("FilterData", toPropertyValues(outputFormat.getExportOptions()))
			};
			try {
				loadAndExport(inputUrl, outputUrl, exportProperties);
			} catch (Throwable throwable) {
				// difficult to provide finer grained error reporting here;
				// OOo seems to throw ErrorCodeIOException most of the time
				throw new OpenOfficeException("conversion failed", throwable);
			}
		}		
	}

	private void loadAndExport(String inputUrl, String outputUrl, PropertyValue[] exportProperties) throws Exception {
		XComponentLoader desktop = openOfficeConnection.getDesktop();
		XComponent document = desktop.loadComponentFromURL(inputUrl, "_blank", 0, new PropertyValue[] {
			property("ReadOnly", Boolean.TRUE),
			property("Hidden", Boolean.TRUE)
		});
		
		refreshDocument(document);
		
		try {
			XStorable storable = (XStorable) UnoRuntime.queryInterface(XStorable.class, document);
			storable.storeToURL(outputUrl, exportProperties);
		} finally {
			document.dispose();
		}
	}
}
