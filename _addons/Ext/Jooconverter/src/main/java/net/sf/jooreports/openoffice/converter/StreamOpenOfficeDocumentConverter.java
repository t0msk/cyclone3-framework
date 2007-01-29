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
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
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
import com.sun.star.lib.uno.adapter.ByteArrayToXInputStreamAdapter;
import com.sun.star.lib.uno.adapter.OutputStreamToXOutputStreamAdapter;
import com.sun.star.uno.UnoRuntime;

/**
 * Alternative stream-based {@link DocumentConverter} implementation.
 * <p>
 * This implementation passes document data to and from the OpenOffice.org
 * service as streams.
 * <p>
 * Stream-based conversions are slower than the default file-based ones (provided
 * by {@link OpenOfficeDocumentConverter}) but they allow to run the OpenOffice.org
 * service on a different machine, or under a different system user on the same
 * machine without file permission problems.
 * 
 * @see OpenOfficeDocumentConverter
 */
public class StreamOpenOfficeDocumentConverter extends AbstractOpenOfficeDocumentConverter {

	public StreamOpenOfficeDocumentConverter(OpenOfficeConnection connection) {
		super(connection);
	}

	public StreamOpenOfficeDocumentConverter(OpenOfficeConnection connection, DocumentFormatRegistry formatRegistry) {
		super(connection, formatRegistry);
	}

	protected void convertInternal(File inputFile, DocumentFormat inputFormat, File outputFile, DocumentFormat outputFormat) {
		InputStream inputStream = null;
		OutputStream outputStream = null;
		try {
			inputStream = new FileInputStream(inputFile);
			outputStream = new FileOutputStream(outputFile);
			convert(inputStream, inputFormat, outputStream, outputFormat);
		} catch (FileNotFoundException fileNotFoundException) {
			throw new IllegalArgumentException(fileNotFoundException.getMessage());
		} finally {
			IOUtils.closeQuietly(inputStream);
			IOUtils.closeQuietly(outputStream);
		}
	}

	protected void convertInternal(InputStream inputStream, DocumentFormat inputFormat, OutputStream outputStream, DocumentFormat outputFormat) {
		String filterName = outputFormat.getExportFilter(inputFormat.getFamily());
		try {
			synchronized (openOfficeConnection) {
				loadAndExport(inputStream, outputStream, filterName, toPropertyValues(outputFormat.getExportOptions()));
			}
		} catch (Throwable throwable) {
			throw new OpenOfficeException("conversion failed", throwable);
		}
	}

	private void loadAndExport(InputStream inputStream, OutputStream outputStream, String filterName, PropertyValue[] filterData) throws Exception {
		XComponentLoader desktop = openOfficeConnection.getDesktop();
		XComponent document = desktop.loadComponentFromURL("private:stream", "_blank", 0, new PropertyValue[] {
			property("ReadOnly", Boolean.TRUE),
			property("Hidden", Boolean.TRUE),
			// doesn't work using InputStreamToXInputStreamAdapter; probably because it's not XSeekable 
			//property("InputStream", new InputStreamToXInputStreamAdapter(inputStream))
			property("InputStream", new ByteArrayToXInputStreamAdapter(IOUtils.toByteArray(inputStream)))
		});
		
		refreshDocument(document);
		
		try {
			XStorable storable = (XStorable) UnoRuntime.queryInterface(XStorable.class, document);
			storable.storeToURL("private:stream", new PropertyValue[] {
				property("FilterName", filterName),
				property("FilterData", filterData),
				property("OutputStream", new OutputStreamToXOutputStreamAdapter(outputStream))
			});
		} finally {
			document.dispose();
		}
	}
}
