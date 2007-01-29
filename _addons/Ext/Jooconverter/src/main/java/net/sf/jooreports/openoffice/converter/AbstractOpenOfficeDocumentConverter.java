package net.sf.jooreports.openoffice.converter;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Iterator;
import java.util.Map;

import org.apache.commons.io.FilenameUtils;

import com.sun.star.beans.PropertyValue;
import com.sun.star.lang.XComponent;
import com.sun.star.uno.UnoRuntime;
import com.sun.star.util.XRefreshable;

import net.sf.jooreports.converter.DocumentConverter;
import net.sf.jooreports.converter.DocumentFormat;
import net.sf.jooreports.converter.DocumentFormatRegistry;
import net.sf.jooreports.converter.XmlDocumentFormatRegistry;
import net.sf.jooreports.openoffice.connection.OpenOfficeConnection;

public abstract class AbstractOpenOfficeDocumentConverter implements DocumentConverter {

	protected OpenOfficeConnection openOfficeConnection;
	private DocumentFormatRegistry documentFormatRegistry;

	public AbstractOpenOfficeDocumentConverter(OpenOfficeConnection connection) {
		this(connection, new XmlDocumentFormatRegistry());
	}

	public AbstractOpenOfficeDocumentConverter(OpenOfficeConnection openOfficeConnection, DocumentFormatRegistry documentFormatRegistry) {
		this.openOfficeConnection = openOfficeConnection;
		this.documentFormatRegistry = documentFormatRegistry;
	}

	protected DocumentFormatRegistry getDocumentFormatRegistry() {
		return documentFormatRegistry;
	}

	public void convert(File inputFile, File outputFile) {
		convert(inputFile, outputFile, null);
	}

	public void convert(File inputFile, File outputFile, DocumentFormat outputFormat) {
		convert(inputFile, null, outputFile, outputFormat);
	}

	public void convert(InputStream inputStream, DocumentFormat inputFormat, OutputStream outputStream, DocumentFormat outputFormat) {
		ensureNotNull("inputStream", inputStream);
		ensureNotNull("inputFormat", inputFormat);
		ensureNotNull("outputStream", outputStream);
		ensureNotNull("outputFormat", outputFormat);
		convertInternal(inputStream, inputFormat, outputStream, outputFormat);
	}

	public void convert(File inputFile, DocumentFormat inputFormat, File outputFile, DocumentFormat outputFormat) {
		ensureNotNull("inputFile", inputFile);
		ensureNotNull("outputFile", outputFile);
		
		if (!inputFile.exists()) {
			throw new IllegalArgumentException("inputFile doesn't exist: " + inputFile);
		}
		if (inputFormat == null) {
			inputFormat = guessDocumentFormat(inputFile);
		}
		if (outputFormat == null) {
			outputFormat = guessDocumentFormat(outputFile);
		}
		if (!inputFormat.isImportable()) {
			throw new IllegalArgumentException("unsupported input format: " + inputFormat.getName());
		}
		if (!inputFormat.isExportableTo(outputFormat)) {
			throw new IllegalArgumentException("unsupported conversion: from " + inputFormat.getName() + " to " + outputFormat.getName());
		}
		convertInternal(inputFile, inputFormat, outputFile, outputFormat);
	}

	protected abstract void convertInternal(InputStream inputStream, DocumentFormat inputFormat, OutputStream outputStream, DocumentFormat outputFormat);
	
	protected abstract void convertInternal(File inputFile, DocumentFormat inputFormat, File outputFile, DocumentFormat outputFormat);
	
	private void ensureNotNull(String argumentName, Object argumentValue) {
		if (argumentValue == null) {
			throw new IllegalArgumentException(argumentName + " is null");
		}
	}

	private DocumentFormat guessDocumentFormat(File file) {
		String extension = FilenameUtils.getExtension(file.getName());
		DocumentFormat format = getDocumentFormatRegistry().getFormatByFileExtension(extension);
		if (format == null) {
			throw new IllegalArgumentException("unknown document format for file: " + file);
		}
		return format;
	}

    protected void refreshDocument(XComponent document) {
		XRefreshable refreshable = (XRefreshable) UnoRuntime.queryInterface(XRefreshable.class, document);
		if (refreshable != null) {
			refreshable.refresh();
		}
	}

	protected static PropertyValue property(String name, Object value) {
    	PropertyValue property = new PropertyValue();
    	property.Name = name;
    	property.Value = value;
    	return property;
    }

	protected static PropertyValue[] toPropertyValues(Map/*<String,Object>*/ properties) {
		PropertyValue[] propertyValues = new PropertyValue[properties.size()];
		int i = 0;
		for (Iterator iter = properties.entrySet().iterator(); iter.hasNext();) {
			Map.Entry entry = (Map.Entry) iter.next();
			propertyValues[i++] = property((String) entry.getKey(), entry.getValue());
		}
		return propertyValues;
	}
}
