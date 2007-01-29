package net.sf.jooreports.openoffice.converter;

import java.io.IOException;

import net.sf.jooreports.converter.DocumentConverter;
import net.sf.jooreports.converter.util.FileType;
import net.sf.jooreports.openoffice.connection.OpenOfficeException;

public class StreamOpenOfficeDocumentConverterTest extends AbstractConverterTest {
	
	private DocumentConverter converter;

	protected void setUp() throws Exception {
		super.setUp();
		converter = new StreamOpenOfficeDocumentConverter(getOpenOfficeConnection(), getDocumentFormatRegistry());
	}

	protected DocumentConverter getDocumentConverter() {
		return converter;
	}

	public void testValidConversion() throws IOException {
		convertAndCheck("hello.odt", "pdf", FileType.PDF);
	}

	public void testCorruptedInputFile() throws IOException {
		try {
			convertAndCheck("invalid.odt", "pdf", FileType.PDF);
			fail("should have detected that the input file was invalid");
		} catch (OpenOfficeException openOfficeException) {
			assertTrue(openOfficeException.getMessage().startsWith("conversion failed"));
		}
	}
}
