package mod.mfchat;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.meetingManager;
import oct.codegen.resultManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import util.Prm;
import util.PrmMtgConstants;
import util.Util;
import util.Util2;

public class PrmMeeting implements PrmMtgConstants
{

	private static userManager		uMgr = null;
	private static meetingManager	mMgr = null;
	private static actionManager	aMgr = null;
	private static resultManager	rMgr = null;
	
	private static boolean isPRM	= Prm.isPRM();
	private static boolean isOMF	= Prm.isOMF();
	
	static {
		try {
			uMgr = userManager.getInstance();
			mMgr = meetingManager.getInstance();
			rMgr = resultManager.getInstance();
			aMgr = actionManager.getInstance();
		}
		catch (PmpException e) {
			e.printStackTrace();
		}
	}

	
	public static String displayActionItems(
			PstAbstractObject[] aiObjArray,
			PstUserAbstractObject pstuser, 
			boolean isRun, 
			String midS,
			int[] ckbCounter
			) 
		throws PmpException
	{
		ckbCounter[0] = 0; // initialized here only, all the checkboxes in the different sections (action/decision/issue) should have unique ids
		int aid, colspanNum;
		String bugIdS, dot, ownerIdS, priority, projIdS, s, subject;
		Date expireDate;
		Object[] respA;
		action obj;
		user uObj;
		String bgcolor = Prm.LIGHT;

		boolean found, even = false;
		StringBuffer out = new StringBuffer(4096);
		SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
		
		/////
		// get also previous action items to list below
		String myTownID = ((user)pstuser).getUserCompanyID();
		int [] lastAiIdArr = aMgr.findId(pstuser, "Type='" + action.TYPE_ACTION
				+ "' && Company='" + myTownID + "' && (Status='" + action.OPEN + "' || Status='" + action.LATE + "')");
		Arrays.sort(lastAiIdArr);
		PstAbstractObject [] lastAiArr = aMgr.get(pstuser, lastAiIdArr);
		String meetingStr = Util2.getAllLinkedMeetings(pstuser, mMgr, midS, true);
		meetingStr = meetingStr.replace(midS, "");
		
		List<PstAbstractObject> al = new ArrayList<PstAbstractObject>(Arrays.asList(lastAiArr));
		for (int i=0; i<lastAiArr.length; i++) {
			s = lastAiArr[i].getStringAttribute("MeetingID");	
			if (s==null || !meetingStr.contains(s)) {			
				al.remove(lastAiArr[i]);
			}
		}
		lastAiArr = al.toArray(new PstAbstractObject[0]);
		//
		/////
		
		if (aiObjArray.length>0 || lastAiArr.length>0) {
			
			// show label
			if (isOMF) {
				out.append(Util.showLabel(label0OMF, labelLen0OMF, isRun)); // last element in arrays will only show if isRun==true
				colspanNum = label0OMF.length*3 - 1;
			}
			else if (isPRM) {
				out.append(Util.showLabel(label0, labelLen0, isRun));
				colspanNum = label0.length*3 - 1;
			}
			else {
				out.append(Util.showLabel(label0CR, labelLen0CR, isRun));	// CR-OMF
				colspanNum = label0CR.length*3 - 1;
			}
			
			PstAbstractObject [] currentAiList = aiObjArray;
	
			for (int m=0; m<2; m++) {
				// first pass is to print current action item
				// second pass is to print all previous open action item
		
				for (int i = 0; i < currentAiList.length; i++)
				{	// the list of action item for this meeting object
					obj = (action)currentAiList[i];
					aid = obj.getObjectId();
					
					if (m>0 && i==0) {
						// previous meeting AI label
						out.append("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
						out.append("<tr><td></td><td colspan='" + colspanNum + "'>");
						out.append("<span style='border-bottom:#336699 1px solid;width:400px;'><img src='../i/spacer.gif' width='300' height='1'/></span></td></tr>");
						out.append("<tr><td></td><td colspan='"
								+ colspanNum + "' class='listlinkbold'>From previous meetings</td></tr>");
						out.append("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
						even = true;	// the next line is grey
					}
		
					subject		= (String)obj.getAttribute("Subject")[0];
					priority	= (String)obj.getAttribute("Priority")[0];
					expireDate	= (Date)obj.getAttribute("ExpireDate")[0];
					ownerIdS	= (String)obj.getAttribute("Owner")[0];
					projIdS		= (String)obj.getAttribute("ProjectID")[0];
					bugIdS		= (String)obj.getAttribute("BugID")[0];
					respA		= obj.getAttribute("Responsible");
		
					if (even)
						bgcolor = Prm.DARK;
					else
						bgcolor = Prm.LIGHT;
					even = !even;
					
					// top gap
					out.append("<tr " + bgcolor + ">" + "<td colspan='"
							+ colspanNum + "'><img src='../i/spacer.gif' width='2' height='10'></td></tr>\n");

					out.append("<tr " + bgcolor + ">");
		
					// Subject
					out.append("<td>&nbsp;</td>");
					out.append("<td valign='top'><table border='0'><tr>");
					out.append("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
					out.append("<td class='plaintext' valign='top'>");
					if (isRun)
						out.append("<a href='javascript:editAC(\""
							+ aid + "\", \"Action\")'>" + subject + "</a>");
					else
						out.append(subject);
					out.append("</td></tr></table></td>\n");
		
					// Responsible
					out.append("<td colspan='2'>&nbsp;</td>");
					out.append("<td class='listtext' width='100' valign='top'>");
		
					found = false;
					int [] ids;
					for (int j=0; j<respA.length; j++)
					{
						s = (String)respA[j];
						if (s == null) break;
						uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));
						out.append("<a class='listlink' href='../ep/ep1.jsp?uid=" + s + "'>");
						out.append((String)uObj.getAttribute(FIRSTNAME)[0]);
						out.append("</a>");
						if (s.equals(ownerIdS))
						{
							found = true;
							out.append("*");
						}
						if (j < respA.length-1 || !found) out.append(", ");
					}
					if (!found)
					{
						// include coordinator/owner into the list of responsible
						uObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
						out.append("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
						out.append((String)uObj.getAttribute(FIRSTNAME)[0]);
						out.append("</a>*");
					}
					out.append("</td>\n");
		
					// Priority {HIGH, MEDIUM, LOW}
					dot = "../i/";
					if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
					else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
					else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
					else {dot += "dot_grey.gif";}
					out.append("<td colspan='3' class='listlink' align='center' valign='top'>");
					out.append("<img src='" + dot + "' alt='" + priority + "'>");
					out.append("</td>\n");
		
					// @ECC041006 support blogging in action/decision/issue
					ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
					out.append("<td colspan='2'>&nbsp;</td>");
					out.append("<td class='listtext' width='30' valign='top' align='center'>");
					out.append("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
					out.append(ids.length + "</a>");
					out.append("</td>\n");
		
					if (!isOMF) {
						// Project id
						out.append("<td colspan='2'>&nbsp;</td>");
						out.append("<td class='listtext' width='40' valign='top' align='center'>");
						if (projIdS != null)
						{
							out.append("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
							out.append(projIdS + "</a>");
						}
						else
							out.append("-");
						out.append("</td>\n");
			
						// Bug id
						out.append("<td colspan='2'>&nbsp;</td>");
						out.append("<td class='listtext' width='40' valign='top' align='center'>");
						if (bugIdS != null)
						{
							out.append("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>");
							out.append(bugIdS + "</a>");
						}
						else
							out.append("-");
						out.append("</td>\n");
					}
		
					// ExpireDate
					out.append("<td colspan='2'>&nbsp;</td>");
					out.append("<td class='listtext_small' width='30' align='center' valign='top'>");
					out.append(df1.format(expireDate));
					out.append("</td>\n");
		
					// update status and delete action item
		
					// delete
					if (isRun)
					{
						out.append("<td colspan='2'>&nbsp;</td>");
						out.append("<td width='35' class='plaintext' align='center' valign='top'>");
						out.append("<input id='ckbox" + ckbCounter[0] + "' type='checkbox' name='delete_" + aid + "'></td>");
						ckbCounter[0]++;
					}
		
					out.append("</tr>\n");
					out.append("<tr " + bgcolor + ">" + "<td colspan='"
							+ colspanNum + "'><img src='../i/spacer.gif' width='2' height='10'></td></tr>\n");
				}	// END: for an AI list
				
				currentAiList = lastAiArr;		// get ready for 2nd pass
			}	// END: for two passes
			
			out.append(CLOSETABLE);
			
		}	// END: if either current meeting AI list or previous AI list is not empty

		return out.toString();
	}
}
