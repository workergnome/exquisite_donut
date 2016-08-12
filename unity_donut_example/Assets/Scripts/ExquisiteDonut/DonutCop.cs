using UnityEngine;
using System;
using System.Net; // For generating IP address
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityOSC;

namespace ExquisiteDonut
{
	public class DonutCop {
		
		private class TimeStampedID{
			public long timeStamp;
			public int id;
			public TimeStampedID(int _id, long _timeStamp) {
				timeStamp = _timeStamp;
				id = _id;
			}
		}

		// Internal variables
		private int lastSecond;         // The last known second (for status pings)
		private int createdSprinkles;        // The # of sprinkles created during this second
		private int id = 0;                      // The ID of this drawing
		private int leftId = 0;                  // The id to the left of the screen
		private int rightId = 0;                 // The id to the right of the screen
		// Received Control Variables
		private int _maxSprinkles = 200;      // The maximum number of Sprinkles allowed on screen
		private int _minSprinkles = 0;      // The minimum number of Sprinkles allowed on screen
		private int _maxNewSprinkles = 10;   // The # of Sprinkles allowed to appear per-second
		private float _maxVelocity = 0.02f;     // The maximum speed a sprinkle can have
		private float _maxAcceleration = 0.001f; // The maximum accelleration for a sprinkle
		// Sprinkle buffer
		private List<Sprinkle> sprinkleBuffer= new List<Sprinkle>();
		// Global variables
		//private IPAddress HOST = IPAddress.Parse("10.0.0.87");
		private IPAddress HOST = IPAddress.Parse("10.0.0.163");
		private int PORT = 9000;
		private int ID_EXPIRATION_IN_SECONDS = 10;
		// Necessary for OSC
		private OSCHandler osc;
		private List<OSCPacket> packets;
		private long lastPacketTimestamp;

		// Known ID's
		private List<TimeStampedID> knownIDs = new List<TimeStampedID>();

		// Script initialization
		public DonutCop() {
			osc = OSCHandler.Instance; //init OSC
			osc.Init();
			osc.CreateServer ("Listener",PORT);
			osc.CreateClient ("Broadcaster", HOST, PORT);
			packets = new List<OSCPacket> ();
		}

		// NOTE: The received messages at each server are updated here
		// Hence, this update depends on your application architecture
		// How many frames per second or Update() calls per frame?
		public void Update(int size) {
			// Update OSC
			osc.UpdateLogs();
			packets = osc.Servers["Listener"].packets;
			int packetCounter = 1;
			while (packetCounter < packets.Count) {
				OSCPacket packet = packets[packets.Count - packetCounter];
				long currentTimestamp = packet.TimeStamp;
				if (currentTimestamp <= lastPacketTimestamp) {
					break;
				}
				string addr = packet.Address;
				if (addr.Equals ("/status")) {
					HandleStatusMessage (packet.Data);
				} else if (addr.Equals ("/control")) {
					HandleControlMessage (packet.Data);
				} else if (addr.Equals ("/sprinkle/" + id.ToString ())) {
					HandleSprinkleMessage (packet.Data);
				}
				packetCounter++;
			}
			if (packetCounter > 1) {
				lastPacketTimestamp = packets [packets.Count - 1].TimeStamp;
			}

			if (CurrentSecond() != lastSecond) {
				SendStatusMessage(size);
				if (id == 0) {
					SendControlMessage();
					RemoveExpiredIds();
				}
				lastSecond = CurrentSecond();
				createdSprinkles = 0;
			}
		}

		public void BroadcastSprinkle(Sprinkle p) {
			List<object> m = p.CreateOSCMessage();
			int id = (p.pos.x < 0) ? leftId : rightId;
			String addr = "/sprinkle/" + id.ToString();
			osc.SendMessageToClient("Broadcaster",addr,m);
		}

		public void MentionNewSprinkle() {
			createdSprinkles++;
		}

		public bool HasNewSprinkles() {
			return sprinkleBuffer.Count > 0;
		}

		public bool AllowedToCreateSprinkle(int sprinkleCount) {
			if (createdSprinkles >= _maxNewSprinkles) {
				return false;
			}
			if (sprinkleCount >= _maxSprinkles) {
				return false;
			}
			return true;
		}

		public Sprinkle GetNextSprinkle() {
			int idx = sprinkleBuffer.Count-1;
			Sprinkle p = sprinkleBuffer[idx];
			sprinkleBuffer.RemoveAt(idx);
			return p;
		}

		// Getter functions
		public int maxSprinkles() { 
			return _maxSprinkles;
		}
		public float maxVelocity() { 
			return _maxVelocity;
		}
		public float maxAcceleration() { 
			return _maxAcceleration;
		}

		// Setter functions
		public void SetId(int _id) { 
			id = _id;
		}

		// Internal Functions
		private int CurrentSecond() {
			return (int)Time.time;
		}
		private void SendStatusMessage(int size) {
			List<object> m = new List<object>();
			m.Add(id);
			m.Add(size);
			osc.SendMessageToClient("Broadcaster","/status",m);
		}
		private void SendControlMessage() {
			// If you haven't heard from anyone, don't send anything.
			if (knownIDs.Count == 0) { 
				return;
			}

			// Generate the char array for IDs
			byte[] data = new byte[255];

			for (int i=0; i<knownIDs.Count; i++) {
				data[i] = (byte)knownIDs[i].id;
			}
			// Calculate my own IDs because I won't be listening to /control
			CalculateIDs (data);
			List<object> m = new List<object>();
			m.Add(data);
			m.Add(_maxSprinkles);
			m.Add(_minSprinkles);
			m.Add(_maxNewSprinkles);
			m.Add(_maxVelocity);
			m.Add(_maxAcceleration);
			osc.SendMessageToClient("Broadcaster", "/control",m);
		}
		private void RemoveExpiredIds() {
			int expiredTime = CurrentSecond();
			if (expiredTime <= ID_EXPIRATION_IN_SECONDS) {
				return;
			} else {
				expiredTime -= ID_EXPIRATION_IN_SECONDS;
			}
			// loop through backwards so we don't get indexing errors
			for (int i = knownIDs.Count-1; i>=0; i--) {
				if (knownIDs[i].timeStamp - expiredTime < 0) {
					Debug.Log("Deleting ID" + knownIDs[i]);
					knownIDs.RemoveAt(i);
				}
			}

		}

		private void HandleStatusMessage(List<object> m) {
			List<object> dataVec = m;
			int statusId = (int)dataVec [0];
			int sprinkles = (int)dataVec [1];
			TimeStampedID newID = new TimeStampedID(statusId, CurrentSecond());
			int idx = knownIDs.FindIndex (x => x.id == newID.id);
			if (idx>=0) {
				knownIDs[idx] = newID;
			} else {
				knownIDs.Add(newID);
			}
			Debug.Log("Received an update from ID " + statusId + ": it has " + sprinkles + " sprinkles.");
		}

		private void HandleControlMessage(List<object> m) {
			List<object> dataVec = m;
			byte[] data    = (byte[]) dataVec [0];
			_maxSprinkles    = (int)dataVec [1];
			_minSprinkles    = (int)dataVec [2];
			_maxNewSprinkles = (int)dataVec [3];
			_maxVelocity     = (float)dataVec [4];
			_maxAcceleration = (float)dataVec [5];
			CalculateIDs (data);
		}

		private void CalculateIDs(byte[] data){
			// Calculate left and right IDs
			int val;
			int maxId = 0;
			leftId = 256;
			rightId = -1;
			for (int i = 0; i < data.Length; ++i) {
				val = (char)(data[i]);
				if (val > id && val < leftId) {
					leftId = val;
				}
				if (val < id && val > rightId) {
					rightId = val;
				}
				if (val > maxId) {
					maxId = val;
				}
			}

			if (leftId == 256) {
				leftId = 0;
			}
			if (rightId == -1) {
				rightId = maxId;
			}

			Debug.Log("My left ID is " + leftId.ToString() + " and my right ID is " + rightId.ToString() +  ".");
		}

		private void HandleSprinkleMessage(List<object> m) {
			Vector2 pos = new Vector2();
			Vector2 vel = new Vector2();
			Vector2 acc = new Vector2();
			List<object> dataVec = m;
			pos.x = 0;
			pos.y = (float)dataVec [0];
			vel.x = (float)dataVec [1];
			vel.y = (float)dataVec [2];
			acc.x = (float)dataVec [3];
			acc.y = (float)dataVec [4];
			float free1 = (float)dataVec [5];
			float free2 = (float)dataVec [6];
			Sprinkle p = new Sprinkle(pos, vel, acc, free1, free2);
			sprinkleBuffer.Add(p);
		}
	}
}
