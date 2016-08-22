using UnityEngine;
using System.Threading;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System;
using UnityOSC;

public delegate void OscMessageHandler (OSCMessage oscM);

public class Osc : MonoBehaviour
{
	private UDPPacketIO OscPacketIO;
	Thread ReadThread;
	private bool ReaderRunning;
	private OscMessageHandler AllMessageHandler;
	Hashtable AddressTable;


	void Start ()
	{
		//do nothing, init must be called
	}

	public void init (UDPPacketIO oscPacketIO)
	{
		OscPacketIO = oscPacketIO;

		// Create the hashtable for the address lookup mechanism
		AddressTable = new Hashtable ();

		ReadThread = new Thread (Read);
		ReaderRunning = true;
		ReadThread.IsBackground = true;
		ReadThread.Start ();
	}


	// Make sure the PacketExchange is closed.
	~Osc ()
	{
		if (ReaderRunning)
			Cancel ();
		//Debug.LogError("~Osc");
	}

	public void Cancel ()
	{
		//Debug.Log("Osc Cancel start");
		if (ReaderRunning) {
			ReaderRunning = false;
			ReadThread.Abort ();
		}
		if (OscPacketIO != null && OscPacketIO.IsOpen ()) {
			OscPacketIO.Close ();
			OscPacketIO = null;
		}
		//Debug.Log("Osc Cancel finished");
	}


	// Read Thread.  Loops waiting for packets.  When a packet is received, it is
	// dispatched to any waiting All Message Handler.  Also, the address is looked up and
	// any matching handler is called.
	private void Read ()
	{
		try {
			while (ReaderRunning) {
				byte[] buffer = new byte[1000];
				int length = OscPacketIO.ReceivePacket (buffer);
				//Debug.Log("received packed of len=" + length);
				if (length > 0) {
					ArrayList messages = Osc.PacketToOscMessages (buffer, length);
					foreach (OSCMessage om in messages) {
						if (AllMessageHandler != null)
							AllMessageHandler (om);
						OscMessageHandler h = (OscMessageHandler)Hashtable.Synchronized (AddressTable) [om.Address];
						if (h != null)
							h (om);
					}
				} else
					Thread.Sleep (20);
			}
		} catch (Exception e) {
			//Debug.Log("ThreadAbortException"+e);
		} finally {
			//Debug.Log("terminating thread - clearing handlers");
			//Cancel();
			//Hashtable.Synchronized(AddressTable).Clear();
		}

	}


	// Send an individual OSC message.  Internally takes the OSCMessage object and
	// serializes it into a byte[] suitable for sending to the PacketIO.
	public void Send (OSCMessage oscMessage)
	{
		byte[] packet = new byte[1000];
		int length = Osc.OscMessageToPacket (oscMessage, packet, 1000);
		OscPacketIO.SendPacket (packet, length);
	}


	// Sends a list of OSC Messages.  Internally takes the OSCMessage objects and
	// serializes them into a byte[] suitable for sending to the PacketExchange.

	//oms - The OSC Message to send.
	public void Send (ArrayList oms)
	{
		byte[] packet = new byte[1000];
		int length = Osc.OscMessagesToPacket (oms, packet, 1000);
		OscPacketIO.SendPacket (packet, length);
	}


	// Set the method to call back on when any message is received.
	// The method needs to have the OscMessageHandler signature - i.e. void amh( OSCMessage oscM )

	// amh - The method to call back on.
	public void SetAllMessageHandler (OscMessageHandler amh)
	{
		AllMessageHandler = amh;
	}


	// Set the method to call back on when a message with the specified
	// address is received.  The method needs to have the OscMessageHandler signature - i.e.
	// void amh( OSCMessage oscM )

	// key - Address string to be matched
	// ah - he method to call back on.
	public void SetAddressHandler (string key, OscMessageHandler ah)
	{
		Hashtable.Synchronized (AddressTable).Add (key, ah);
	}

	// General static helper that returns a string suitable for printing representing the supplied
	// OscMessage.

	//  message - The OSCMessage to be stringified
	// returns The OSCMessage as a string.
	public static string OscMessageToString (OSCMessage message)
	{
		StringBuilder s = new StringBuilder ();
		s.Append (message.Address);
		foreach (object o in message.Data) {
			s.Append (" ");
			s.Append (o.ToString ());
		}
		return s.ToString ();
	}

	// Turns raw bytes into a string for debugging
	private static string Dump (byte[] packet, int start, int length)
	{
		StringBuilder sb = new StringBuilder ();
		int index = start;
		while (index < length)
			sb.Append (packet [index++] + "|");
		return sb.ToString ();
	}

	// Takes a packet (byte[]) and turns it into a list of OscMessages.

	//packet - The packet to be parsed
	// length - The length of the packet.
	// returns - An ArrayList of OscMessages.
	public static ArrayList PacketToOscMessages (byte[] packet, int length)
	{
		ArrayList messages = new ArrayList ();
		ExtractMessages (messages, packet, 0, length);
		return messages;
	}


	// Puts an array of OscMessages into a packet (byte[]).
	public static int OscMessagesToPacket (ArrayList messages, byte[] packet, int length)
	{
		int index = 0;
		if (messages.Count == 1)
			index = OscMessageToPacket ((OSCMessage)messages [0], packet, 0, length);
		else {
			// Write the first bundle bit
			index = InsertString ("#bundle", packet, index, length);
			// Write a null timestamp (another 8bytes)
			int c = 8;
			while ((c--) > 0)
				packet [index++]++;
			// Now, put each message preceded by it's length
			foreach (OSCMessage oscM in messages) {
				int lengthIndex = index;
				index += 4;
				int packetStart = index;
				index = OscMessageToPacket (oscM, packet, index, length);
				int packetSize = index - packetStart;
				packet [lengthIndex++] = (byte)((packetSize >> 24) & 0xFF);
				packet [lengthIndex++] = (byte)((packetSize >> 16) & 0xFF);
				packet [lengthIndex++] = (byte)((packetSize >> 8) & 0xFF);
				packet [lengthIndex++] = (byte)((packetSize) & 0xFF);
			}
		}
		return index;
	}


	// Creates a packet (an array of bytes) from a single OscMessage.

	// oscM - The OSCMessage to be returned as a packet.
	//packet - The packet to be populated with the OscMessage.
	//length - The usable size of the array of bytes.
	//returns - The length of the packet
	public static int OscMessageToPacket (OSCMessage oscM, byte[] packet, int length)
	{
		return OscMessageToPacket (oscM, packet, 0, length);
	}

	// Creates an array of bytes from a single OscMessage.  Used internally.
	private static int OscMessageToPacket (OSCMessage oscM, byte[] packet, int start, int length)
	{		
		int index = start;
		oscM.BinaryData.CopyTo (packet, index);
		index += oscM.BinaryData.Length;
		return index;
	}

	// Receive a raw packet of bytes and extract OscMessages from it.  Used internally.
	private static int ExtractMessages (ArrayList messages, byte[] packet, int start, int length)
	{
		int index = start;
		switch ((char)packet [start]) {
		case '/':
			index = ExtractMessage (messages, packet, index, length);
			break;
		case '#':
			string bundleString = ExtractString (packet, start, length);
			if (bundleString == "#bundle") {
				// skip the "bundle" and the timestamp
				index += 16;
				while (index < length) {
					int messageSize = (packet [index++] << 24) + (packet [index++] << 16) + (packet [index++] << 8) + packet [index++];
					//int newIndex = 
					ExtractMessages (messages, packet, index, length);
					index += messageSize;
				}
			}
			break;
		}
		return index;
	}

	// Extracts a messages from a packet.
	private static int ExtractMessage (ArrayList messages, byte[] packet, int start, int length)
	{
		int index = start;
		OSCMessage m = OSCMessage.Unpack(packet,ref index);
		messages.Add (m);
		return index;
	}
		
	// Removes a string from a packet.  Used internally.
	private static string ExtractString (byte[] packet, int start, int length)
	{
		StringBuilder sb = new StringBuilder ();
		int index = start;
		while (packet [index] != 0 && index < length)
			sb.Append ((char)packet [index++]);
		return sb.ToString ();
	}

	// Inserts a string, correctly padded into a packet.  Used internally.
	private static int InsertString (string s, byte[] packet, int start, int length)
	{
		int index = start;
		foreach (char c in s) {
			packet [index++] = (byte)c;
			if (index == length)
				return index;
		}
		packet [index++] = 0;
		int pad = (s.Length + 1) % 4;
		if (pad != 0) {
			pad = 4 - pad;
			while (pad-- > 0)
				packet [index++] = 0;
		}
		return index;
	}
}

