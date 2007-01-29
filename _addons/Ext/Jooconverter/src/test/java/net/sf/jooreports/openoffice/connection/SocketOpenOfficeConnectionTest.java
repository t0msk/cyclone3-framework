package net.sf.jooreports.openoffice.connection;

import java.io.IOException;
import java.net.ConnectException;

import junit.framework.TestCase;

public class SocketOpenOfficeConnectionTest extends TestCase {

	public void testInvalidConnection() throws ConnectException {
		OpenOfficeConnection connection = new SocketOpenOfficeConnection(59999);
		try {
			connection.connect();
			fail("should throw exception");
		} catch (ConnectException connectException) {
			// expected
		}
	}

	public void testConnectAndDisconnect() throws IOException {
		OpenOfficeConnection connection = new SocketOpenOfficeConnection();
		connection.connect();
		assertTrue(connection.isConnected());
		assertNotNull(connection.getDesktop());
		connection.disconnect();
	}

	public void testAutoConnect() throws IOException {
		OpenOfficeConnection connection = new SocketOpenOfficeConnection();
		assertFalse(connection.isConnected());
		assertNotNull(connection.getDesktop());
		assertTrue(connection.isConnected());
		connection.disconnect();
	}

	public void testAutoReconnectAfterUnexpectedDisconnection() throws IOException {
		SocketOpenOfficeConnection connection = new SocketOpenOfficeConnection();
		connection.connect();
		assertTrue(connection.isConnected());
		assertNotNull(connection.getDesktop());
		
		connection.simulateUnexpectedDisconnection();
		assertFalse(connection.isConnected());
		
		// getDesktop() should force the reconnect
		assertNotNull(connection.getDesktop());
		assertTrue(connection.isConnected());
		
		connection.disconnect();
	}

	public void testMultipleConnections() throws Exception {
		OpenOfficeConnection connection1 = new SocketOpenOfficeConnection();
		OpenOfficeConnection connection2 = new SocketOpenOfficeConnection();
		
		connection1.connect();
		assertTrue(connection1.isConnected());
		connection2.connect();
		assertTrue(connection2.isConnected());
		
		connection1.disconnect();
		connection2.disconnect();
	}
}
