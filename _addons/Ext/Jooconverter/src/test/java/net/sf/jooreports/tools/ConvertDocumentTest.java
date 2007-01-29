package net.sf.jooreports.tools;

import java.io.File;

import net.sf.jooreports.converter.util.FileType;
import net.sf.jooreports.openoffice.converter.AbstractConverterTest;

public class ConvertDocumentTest extends AbstractConverterTest {

	public void testValidConversion() throws Exception {
		File inputFile = getTestFile("hello.odt");
		File outputFile = createTempFile("pdf");
		
		int exitCode = ConvertDocument.process(new String[] {
			inputFile.getAbsolutePath(),
			outputFile.getAbsolutePath()
		});
		assertEquals(ConvertDocument.EXIT_CODE_SUCCESS, exitCode);
		checkOutputFile(outputFile, FileType.PDF);
	}

	public void testInsufficientArguments() throws Exception {
		assertEquals(ConvertDocument.EXIT_CODE_TOO_FEW_ARGS, ConvertDocument.process(new String[0]));
		assertEquals(ConvertDocument.EXIT_CODE_TOO_FEW_ARGS, ConvertDocument.process(new String[] { "one" }));
	}
}
