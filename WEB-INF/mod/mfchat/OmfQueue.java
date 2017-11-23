//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/WEB-INF/classes/mod/mfchat/OmfQueue.java,v 1.7 2006/11/11 18:09:43 edwardc Exp $
//
//	File:	$RCSfile: OmfQueue.java,v $
//	Author:	ECC
//	Date:	$Date: 2006/11/11 18:09:43 $
//  Description:
//      Implement queue for OMF. 
//
//	Modification:
/////////////////////////////////////////////////////////////////////

package mod.mfchat;

public class OmfQueue {
	static final int MAX_QUEUE_SIZE			= 250;
	static final int iEXPR_QUEUE			= 0;
	static final int iCHAT_QUEUE			= 1;
	static final int iINPUT_QUEUE			= 2;

	static public final int MAX_INPUT_QUEUE_NUM	= 10;
	
	// members
	private Object [] m_queue;
	private int m_head;
	private int m_tail;
	private int m_index;		// monotonically increasing when inserting new element
	private int m_qSize;		// max queue size
	
	private StringBuffer m_buf;	// for remembering the chat buffer (if needed)
	private int m_offset;
	private int m_idxDiff;		// the distance between mtg note counter and queue index
	
	private String m_inputUser;	// used by input queue to remember the current user entering input
	
	
	public OmfQueue()
	{
		this(MAX_QUEUE_SIZE);	// default queue size
	}
	public OmfQueue(int qSize)
	{
		m_qSize = qSize;
		m_queue = new Object[m_qSize];
		m_head = -1;
		m_tail = 0;
		m_index = 0;			// there are a total of m_index objects inserted so far
	}
	
	public OmfQueue(int type, int maxQsize)
	{
		this(maxQsize);
		if (type == iCHAT_QUEUE)
		{
			m_buf = new StringBuffer(8192);	
			m_offset = 0;
		}
		else if (type == iINPUT_QUEUE)
			m_inputUser = null;
	}
	
	// return true if enqueue is successful; return false if it fails
	public boolean enqueue(Object o)
	{
		//System.out.println("enqueue");		
		synchronized (this)
		{
			// insert the object into the tail position
			int newTail = incIdx(m_tail);
			if (newTail == m_head) return false;			// if tail is too close to head, don't do it
			
			m_queue[m_tail] = o;
			m_tail = newTail;
			m_index++;										// added an element
			if (m_head < 0) m_head = 0;						// first time: initialize
			//System.out.println("   head,tail=("+m_head+", "+m_tail+") m_index="+m_index);	
			return true;
		}
	}
	
	public Object dequeue() {return dequeue(null);}
	
	public Object dequeue(Object o)
	{
		Object retObj = null;
		synchronized (this)
		{
			if (m_head < 0) return null;		// not initialized yet
			if (m_head == m_tail) return null;	// nothing on the queue
			if (o == null)
			{
				// return and remove the object at the head
				retObj = m_queue[m_head];
				m_queue[m_head] = null;
				m_head = incIdx(m_head);
			}
			else
			{
				// dequeue the specific item
				// first find the item
				Object obj;
				int start = m_head;
				while (start != m_tail)
				{
					obj = m_queue[start];
					if (obj!=null && obj.equals(o))
					{
						// found
						retObj = obj;
						break;
					}
					start = incIdx(start);	// get next index
				}
				if (retObj != null)
				{
					// delete the found item and move other items on queue
					while (start != m_head)
					{
						int prev = decIdx(start);
						m_queue[start] = m_queue[prev];
						start = prev;
					}
					m_queue[m_head] = null;		// all prev has been moved up
					m_head = incIdx(m_head);	// set m_head
				}
			}
			return retObj;
		}
	}
	
	public boolean found(Object o)
	{
		synchronized (this)
		{
			if (m_head < 0) return false;		// not initialized yet
			if (m_head == m_tail) return false;	// nothing on the queue
			if (o == null) return false;
			Object obj;
			int idx = m_head;
			while (idx != m_tail)
			{
				obj = m_queue[idx];
				if (obj!=null && obj.equals(o))
					return true;	// found
				idx = incIdx(idx);	// next element
			}
		}
		return false;
	}
	
	// set the queue head to remove elements on queue, up to a certain distance from tail
	public void setQueueHead(int left)
	{
		synchronized (this)
		{
			// remove the objects by moving the head towards the tail with 
			if (m_head < 0) return;		// not initialized yet
			if ( ((m_tail-m_head-1+m_qSize) % m_qSize) < left ) return;	// not enough elements left

			int newHead = (m_tail - left + m_qSize) % m_qSize;
			m_head = newHead;
		}
	}

	public Object peek(int idx)
	{
		synchronized (this)
		{
			// return the object at the position idx without removing the object
			if (m_head < 0) return null;			// not initialized yet
			if (decIdx(idx)==m_tail) return null;	// nothing to read

			int pos = idx % m_qSize;				// next beginning read position
			return ((m_queue[pos]));
		}
	}
	
	public int insertChat(StringBuffer chatStrBuf)
	{
		// insert the string into the buffer and return the offset of this string
		// this is method expects the caller to synchronize itself
		int off = m_offset;
		m_buf.append(chatStrBuf);
		m_offset += chatStrBuf.length();
		return off;
	}
	
	public void setIdxDiff(int diff) {m_idxDiff = diff;}
	public int getIdxDiff() {return m_idxDiff;}
	
	public int getIndex() {return m_index;}
	public int getHead() {return m_head;}
	public int getTail() {return m_tail;}
	public int getLastIndex() {return ((m_tail-1+m_qSize)%m_qSize);}
	public int incIdx(int idx) {return (idx+1)%m_qSize;}
	public int decIdx(int idx) {return (idx-1+m_qSize)%m_qSize;}
	
	public StringBuffer getBuffer() {return m_buf;}
	public String getInputUser() {return m_inputUser;}
	public void setInputUser(String uObjName) {m_inputUser = uObjName;}
}
