////////////////////////////////////////////////////
//	Copyright (c) 20067, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfPresence.java
//	Author:	ECC
//	Date:	02/08/08
//	Description:
//		Implementation of OmfPresence class.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Vector;

import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import util.Util;
import util.Util2;

/**
 * @author edwardc
 *
 */
public class OmfPresence {
	
	public static final int MAX_SHOWN		= 10;			// max member shown on page

	private static HashMap<String,Date> onlineHash;		// Stores the current session number
	private static userManager uMgr;
	private static userinfoManager uiMgr;

	// Initialize static variables
	static {
		onlineHash	= new HashMap<String,Date>();
		try {
			uMgr	= userManager.getInstance();
			uiMgr	= userinfoManager.getInstance();
		} catch (PmpException e) {}
	}
	
	public static HashMap<String,Date> getHash() {return onlineHash;}
	
	public static void setOnline(int uid) {setOnline(String.valueOf(uid));}
	
	synchronized public static void setOnline(String uidS)
	{
		if (uidS != null)
			onlineHash.put(uidS, new Date());
	}
	
	synchronized public static void setOffline(String uidS)
	{
		if (uidS != null)
			onlineHash.remove(uidS);
	}
	
	public static boolean isOnline(String uidS) {return onlineHash.containsKey(uidS);}
	
	//
	// caller pass in an int array of user ids.  This method returns two arrays of
	// int in the return Vector ret.  The first contains all user ids who are online;
	// the second contains the rest of the ids in the pass-in array.  Note that
	// even if any of these two arrays is empty, this method will return an array of
	// 0 size.
	//
	private static void getOnlineUsers(int [] ids, int myId, Vector ret)
	{
		int size = ids.length;
		int [] ar1 = new int [size];
		int [] ar2 = new int [size];
		int ct1=0, ct2=0;
		
		for (int i=0; i<ids.length; i++)
		{
			// go through the list of ids and split them to two arrays
			if (onlineHash.containsKey(String.valueOf(ids[i])))
				ar1[ct1++] = ids[i];	// online list
			else
				ar2[ct2++] = ids[i];	// offline list
		}
		
		// get ready to return to caller
		int [] tempAr = new int [ct1];
		for (int i=0; i<ct1; i++)
			tempAr[i] = ar1[i];
		ret.addElement(tempAr);				// first return the online list
		
		tempAr = new int [ct2];
		for (int i=0; i<ct2; i++)
			tempAr[i] = ar2[i];
		ret.addElement(tempAr);				// second return the offline list
		
		return;
	}
	
	// return a string of uids who's currently online, separated by ";"
	// also return a StringBuffer sBuf containing the XML to be displayed
	public static String displayMemberList(
			PstUserAbstractObject me,
			StringBuffer sBuf,					// return the XML to be displayed
			Vector vec,							// caller might have done the split already
			int [] memIds,
			int beginIdx,
			boolean isMyFriends,
			boolean isSearch,
			boolean isDisplayFromMem)
		throws PmpException
	{
		int myUid = me.getObjectId();
		Date now = new Date();
		
		// construct myFriends hash for comparison later
		Hashtable hsFriends = new Hashtable();
		Object [] oA = me.getAttribute("TeamMembers");
		for (int i=0; i<oA.length; i++)
		{
			if (oA[i] == null) break;
			hsFriends.put((Integer)oA[i], "");
		}
		
		// @ECC020808 call to split the memIds to two arrays
		if (vec == null)
		{
			vec = new Vector();
			getOnlineUsers(memIds, myUid, vec);
		}
		int [] memIdsOnline  = (int [])vec.elementAt(0);
		int [] memIdsOffline = (int [])vec.elementAt(1);
		int resNum = memIdsOnline.length + memIdsOffline.length;	// total no. of members on list
		
		// construct the uid string list of all those online
		String onlineStr = getOnlineStr(memIdsOnline);

		boolean bShowOnline;
		int idx;							// idx is used to point into one of the two int arrays
		if (beginIdx<memIdsOnline.length)
		{
			memIds = memIdsOnline;			// start from online users
			bShowOnline = true;
			idx = beginIdx;
		}
		else
		{
			memIds = memIdsOffline;
			bShowOnline = false;
			idx = beginIdx - memIdsOnline.length;
		}
		
		PstAbstractObject [] memArr = uMgr.get(me, memIds);
		Util.sortUserArray(memArr, true);	// sort by fullName

		String s, name, motto, picURL, activeS;
		int numOfFriends, id;
		user uObj;
		Date dt;
		
		sBuf.append("<table id='memListTable' width='100%' border='0' cellspacing='0' cellpadding='0'>");
		for (int i=beginIdx; i<resNum&&i<beginIdx+MAX_SHOWN; i++)
		{
			try
			{
				if (memIds==memIdsOnline && i>=memIdsOnline.length)
				{
					memIds = memIdsOffline;			// switch to the 2nd array
					memArr = uMgr.get(me, memIds);
					Util.sortUserArray(memArr, true);
					idx = 0;						// start from the beginning of the array
					bShowOnline = false;
				}
				uObj = (user)memArr[idx++];
				id = uObj.getObjectId();
				picURL = Util2.getPicURL(uObj);
				name = uObj.getFullName();
				numOfFriends = uObj.getAttribute("TeamMembers").length;
				motto = (String)uObj.getAttribute("Motto")[0];
				if (motto==null || motto.equals("null"))
				{
					if (id == myUid)
						motto = "<a href='javascript:action(7," + id + ");' class='listlink'>Add Motto</a>";
					else
						motto = "<font color='#aaaaaa'>Motto / Reminder for self</font>";
				}
				s = " href='javascript:show_action(" + id + ",null,null,\""
						+ (String)uObj.getAttribute("FirstName")[0] + "\");'";		// href
				sBuf.append("<tr><td colspan='2'><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
				sBuf.append("<td width='200' align='left'><hr class='evt_hr' /></td>");
				if (isMyFriends)
				{
					// friend's list
					if (isSearch && !isDisplayFromMem && id!=myUid)
					{
						sBuf.append("<td valign='bottom' align='center' title=\"Remove from My friends's list\"><a class='listlink' href='javascript:friend(\"remove\", " + id + ", \"" + name + "\");'><img src='../i/icon_delete.gif' border='0' /></a></td>");
						sBuf.append("<td valign='bottom' align='center' title='Block and remove this person'><a class='listlink' href='javascript:friend(\"block\", " + id + ", \"" + name + "\");'><img src='../i/icon_shield.gif' border='0' /></a></td>");
					}
				}
				else if (id!=myUid && !hsFriends.containsKey(new Integer(id)))
				{
					// circle members: add to My Friends
					sBuf.append("<td width='24'>&nbsp;</td>");
					sBuf.append("<td valign='bottom' align='center' title='Add " + name + " to My Friends'><a class='listlink' href='javascript:friend(\"add\", " + id + ", \"" + name + "\");'><img src='../i/icon_add.gif' border='0' /></a></td>");
				}
				if (!isSearch || isDisplayFromMem)
				{
					sBuf.append("<td width='24'>&nbsp;</td>");
					sBuf.append("<td valign='bottom' align='center' title='Ignore this person from search result'><a class='listlink' href='javascript:friend(\"ignore\", " + id + ", \"" + name + "\");'><img src='../i/icon_deleteG.gif' border='0' /></a></td>");
				}
	
				sBuf.append("</tr></table></td></tr>");
				sBuf.append("<tr><td width='50' ");
//				if (bShowOnline /*|| id==myUid*/)
//					sBuf.append("style='border:3px #82e600 solid;' ");

				//sBuf.append("><a class='listlink'" + s + "><img src='" + picURL + "' width='50' border='0'/></a></td>");
				sBuf.append("><a class='listlink'" + s + "><img src='" + picURL + "' width='50' ");
				if (bShowOnline)
					sBuf.append("style='border:3px #82e600 solid;' ");
				sBuf.append("/></a></td>");
				sBuf.append("<td class='plaintext' valign='top' ><table cellspacing='0' cellpadding='3' width='100%'><tr><td ");
				if (bShowOnline)
				{
					sBuf.append("style='background:url(../i/green.gif) no-repeat'>");
					sBuf.append("<a class='listlink'" + s + ">" + name + "</a></td>");
					sBuf.append("<td class='online'>online&nbsp;&nbsp;</td>");
					sBuf.append("</tr>");
				}
				else
				{
					// not online, show last login
					sBuf.append("><a class='listlink'" + s + ">" + name + "</a></td>");
					dt = (Date)uiMgr.get(me, String.valueOf(id)).getAttribute("LastLogin")[0];
					activeS = getGapBetweenDates(now, dt);
					sBuf.append("<td class='offline'>" + activeS + "</td>");
					sBuf.append("</tr>");
				}
				sBuf.append("<tr><td colspan='2'");
				if (id == myUid) sBuf.append("id='myMotto' ");
				sBuf.append("class='plaintext' style='padding-left:4px;' width='190'>" + motto + "<br>(");
				sBuf.append(numOfFriends + " friends)</td></tr>");
				sBuf.append("</table></td>");
				sBuf.append("</tr>");
				sBuf.append("<tr><td colspan='2'><div id='" + id + "' class='plaintext' style='display:none;'></div></td></tr>");
			}
			catch (PmpException e) {continue;}
		}
		sBuf.append("</table>");
		
		return onlineStr;
	}	// END: displayMemberList()
	
	public static String getGapBetweenDates(Date now, Date dt)
	{
		String retS = "";
		if (dt != null)
		{
			int diff = (int)((now.getTime() - dt.getTime()) / 60000);		// min
			if (diff > 60)
			{
				diff /= 60;			// hrs
				if (diff > 24)
				{
					diff /= 24;		// days
					if (diff > 30)
					{
						diff /= 30;	// mos
						retS = diff + " mos ago";
					}
					else
						retS = diff + " days ago";
				}
				else
					retS = diff + " hrs ago";
			}
			else
			{
				if (diff <= 0) retS = "1 min ago";
				else retS = diff + " mins ago";
			}
			retS = "(" + retS + ")";
		}

		return retS;
	}

	// with an int [], return  sorted String of ids separated by ";"
	// return "" if no one is online
	private static String getOnlineStr(int [] ids)
	{
		StringBuffer tempBuf = new StringBuffer(1024);
		Arrays.sort(ids);					// need to sort for comparison
		for (int i=0; i<ids.length; i++)
		{
			tempBuf.append(String.valueOf(ids[i]));
			tempBuf.append(";");
		}
		String onlineStr = "";
		if (tempBuf.length() > 0)
			onlineStr = tempBuf.substring(0, tempBuf.length()-1);	// cut the last ";"
		return onlineStr;
	}
	
	// caller passes in an onlineStr which contains list of users online in the last check.
	// If the current user online is different from that string, new int[]s will be returned.
	// The new int[]s contain the list uids of all members online and offline, stored in the Vector.
	// If there is no change, it will return null.
	public static Vector checkOnline(
			PstUserAbstractObject pstuser, 
			String onlineStr,
			int circleId)
	{
		int [] memIds = null;
		try
		{
			if (circleId <= 0)
			{
				// listing my friends
				Object [] oA = pstuser.getAttribute("TeamMembers");
				if (oA[0] != null)
					memIds = Util2.toIntArray(oA);
			}
			else
			{
				// list circle members
				memIds = uMgr.findId(pstuser, "Towns=" + circleId);
			}
		}
		catch (PmpException e) {return null;}
		
		// split the memIds to get online members
		Vector vec = new Vector();
		getOnlineUsers(memIds, pstuser.getObjectId(), vec);
		int [] memIdsOnline  = (int [])vec.elementAt(0);
		String newOnlineStr = getOnlineStr(memIdsOnline);
		if (!onlineStr.equals(newOnlineStr))
			return vec;
		else
			return null;			// no change: return null
	}	// END: checkOnline()

}
