using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

namespace ExquisiteDonut
{
	// Class for adding and deleting sprinkles in a way that won't
	// cause indexing errors
	public class SprinkleManager : IEnumerable<Sprinkle>
	{
		private List<Sprinkle> _sprinkles;
		private List<int> _sprinkleIDs;
		private List<int> _sprinklesToRemove;
		private int idCounter = 0;
		private int maxSprinkles;

		public SprinkleManager(int _maxSprinkles){
			_sprinkles = new List<Sprinkle> ();
			_sprinklesToRemove = new List<int> ();
			maxSprinkles = _maxSprinkles;
		}

		// Should be called in a main loop. Deletes sprinkles to be removed
		public void ClearRemoved(){
			// Sort descending to not screw up our indexing
			_sprinklesToRemove.Sort();
			_sprinklesToRemove.Reverse();
			// Remove and publish sprinkles set for deletion
			while(_sprinklesToRemove.Count>0){
				int idx = _sprinklesToRemove[0];
				_sprinkles.RemoveAt(idx);
				_sprinklesToRemove.Remove(idx);
			}
		}

		public void SetMaxSprinkles(int val){
			maxSprinkles = val;
		}

		// Remove a sprinkle by index (Won't actually be done until update)
		public void RemoveAt(int idx)
		{
			_sprinklesToRemove.Add (idx);
		}
		// Remove a sprinkle (Won't actually be done until update)
		public void Remove(Sprinkle p)
		{
			int idx = _sprinkles.IndexOf (p);
			_sprinklesToRemove.Add (idx);
		}
		// Add a new sprinkle
		public void Add (Sprinkle p)
		{
			p.id = idCounter;
			idCounter = (idCounter + 1) % maxSprinkles;
			_sprinkles.Add (p);
		}
		// Access the inner sprinkle array
		public Sprinkle this[int idx]
		{
			get{ return _sprinkles [idx]; }
			set{ _sprinkles [idx] = value; }
		}
		// Get number of sprinkles
		public int Count
		{
			get{ return _sprinkles.Count; }
		}
		// Let the user use the inner sprinkle list for LINQ ForEach Where, Select, etc.
		public IEnumerator<Sprinkle> GetEnumerator() { return _sprinkles.GetEnumerator(); }
		IEnumerator IEnumerable.GetEnumerator() { return GetEnumerator(); }
	}
}

