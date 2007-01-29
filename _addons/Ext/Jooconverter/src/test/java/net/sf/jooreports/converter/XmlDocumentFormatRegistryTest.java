package net.sf.jooreports.converter;

import junit.framework.TestCase;

public class XmlDocumentFormatRegistryTest extends TestCase {

	private DocumentFormatRegistry defaultRegistry = new XmlDocumentFormatRegistry();

	public void testDefaults() {
		DocumentFormat pdf1 = defaultRegistry.getFormatByFileExtension("pdf");
		assertNotNull(pdf1);
		DocumentFormat pdf2 = defaultRegistry.getFormatByMimeType("application/pdf");
		assertNotNull(pdf2);
		assertEquals(pdf1, pdf2);
	}

	public void testUnknownFormats() {
		DocumentFormat unknown1 = defaultRegistry.getFormatByFileExtension("xyz");
		assertNull(unknown1);
		DocumentFormat unknown2 = defaultRegistry.getFormatByMimeType("type/xyz");
		assertNull(unknown2);
	}

	public void testNullConfiguration() {
		try {
			new XmlDocumentFormatRegistry(null);
			fail("should throw exception");
		} catch (IllegalArgumentException illegalArgumentException) {
			// expected
		}
	}
}
