package net.sf.jooreports.openoffice.connection;

import java.io.IOException;
import java.net.ConnectException;

import junit.framework.TestCase;

public class PipeOpenOfficeConnectionTest extends TestCase {

	public void testInvalidConnection() throws ConnectException {
		OpenOfficeConnection connection = new PipeOpenOfficeConnection("no-such-pipe-name");
		try {
			connection.connect();
			fail("should throw exception");
		} catch (ConnectException connectException) {
			// expected
		}
	}

	public void testConnectAndDisconnect() throws IOException {
		OpenOfficeConnection connection = new PipeOpenOfficeConnection();
		connection.connect();
		assertTrue(connection.isConnected());
		assertNotNull(connection.getDesktop());
		connection.disconnect();
	}
}
