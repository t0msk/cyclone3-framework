package net.sf.jooreports.converter;

import junit.framework.TestCase;

public class DocumentFamilyTest extends TestCase {

	public void testValidFamilies() {
		assertEquals(DocumentFamily.TEXT, DocumentFamily.getFamily("Text"));
		assertEquals(DocumentFamily.SPREADSHEET, DocumentFamily.getFamily("Spreadsheet"));
		assertEquals(DocumentFamily.PRESENTATION, DocumentFamily.getFamily("Presentation"));
	}

	public void testInvalidFamily() {
		try {
			DocumentFamily.getFamily("Invalid");
			fail("invalid family should throw an exception");
		} catch (IllegalArgumentException illegalArgumentException) {
			// expected
		}
	}
}
