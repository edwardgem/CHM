////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	NewClass.java
//	Author:	ECC
//	Date:	06/15/06
//	Description:
//		Implementation of NewClass class.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

/**
 * @author edwardc
 *
 */
public class PrmColor
{
	private final String [] m_colorArray = {
		"#CC0000",		// 0
		"#0000FF",
		"#208000",
		"#a00080",
		"#400080",
		"#666600",		// 5
		"#CC00CC",
		"#9900FF",
		"#FF9933",
		"#DDDD00",
		"#FFCC99",		// 10
		"#BB0000",
		"#CC8800",
		"#FF5500",
		"#990099",
		"#114488",		// 15
		"#44FF00",
		"#000000",
		"#666666",
		"#999999",
		"#DDDDDD",		// 20
		"#CCFF00",
		"#CCAA77",
		"#CC9999",
		"#99EEEE"
	};
	
	private final int m_max = m_colorArray.length;
	
	private int m_index = 0;		// the next unused color, but someone really might already occupy this
	
	private String [] m_idArray;	// the index of userId; it matches to the color in m_colorArray that the user is using
	
	public int length() {return m_index;}
	public String getId(int idx) {return m_idArray[idx];}

	public PrmColor()
	{
		// TODO Auto-generated constructor stub
		m_idArray = new String[m_max];		// init to null
	}
	
	public String getColor()
	{
		if (m_index >= m_max) return("#000000");		// all used: return black	
		return (m_colorArray[m_index++]);
	}
	
	public String getColor(String idS)
	{
		// use the id to search for a match from the current used slots, if found,
		// return the corresponding color string; else put the id in the next slot
		// and return that color string.
		if (m_index >= m_max) return("#000000");		// all used: return black
		
		boolean found = false;
		int idx;
		for (idx=0; idx<m_index; idx++)
		{
			if (idS.equals(m_idArray[idx]))
			{
				found = true;
				break;
			}
		}
		
		if (!found)
		{
			// put the id into the next slot and return color
			//System.out.println("-- PrmColor: getColor[" + idS + "] allocate new color at idx = " + m_index);
			while (m_index < m_max) {
				if (m_idArray[m_index] == null) {
					m_idArray[m_index] = idS;
					break;			// got it
				}
				m_index++;			// already occupied, try the next slot
			}
			return (m_colorArray[m_index++]);	// remember to increment to the next slot
		}
		else
			return (m_colorArray[idx]);			// id match
	}
	
	// call at startup time to re-assign the color to user
	// must be call in sequence based on m_index
	// put the user id into the ID Array, return the corresponding color
	/* this method is not right because the users might already have allocated with
	 * another color in last chat section, how can I blindly assign color to them now?
	public String setColor(int idx, String idS)
	{
		if (idx != m_index) return null;		// Error: out of sequence
		if (idx >= m_max) return ("#000000");
		m_idArray[idx] = idS;
		return m_colorArray[m_index++];
	}
	 */
	
	
	/**
	 * go through the color array to find a match, if found, return the index
	 * @param colorStr
	 * @return index into the color array, or -1 if no match
	 */
	public int matchColor(String uidS, String colorStr)
	{

		for (int i=0; i<m_max; i++) {
			if (m_colorArray[i].equals(colorStr)) {
				if (m_idArray[i] == null) {
					m_idArray[i] = uidS;
					return i;		// found match
				}
				break;				// found but already occupied, return -1
			}
		}
		return -1;
	}
	
	public int getMax() {return m_max;}
}
