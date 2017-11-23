//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   result.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//		Implementation of result class
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//		@ECC090806	Support forum blog.
// 		@SWS092806 	Delete current blog's attachment objects and remove from index
//
/////////////////////////////////////////////////////////////////////
//
// result.java : implementation of the result class
//

package oct.codegen;
import java.io.File;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.Date;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmEvent;
import util.PrmLog;
import util.TaskInfo;
import util.Util;
import util.Util2;

/**
*
* <b>General Description:</b>  result extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "result" organization.
*
* The result class provides a facility to modify data of an existing result object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.resultManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class result extends PstAbstractObject

{
	public final static String TYPE_BUG_BLOG	= "Bug";		// bug blog
	public final static String TYPE_PROJ_BLOG	= "Project";	// project blog
	public final static String TYPE_TASK_BLOG	= "Task";		// task blog
	public final static String TYPE_ACTN_BLOG	= "Action";		// action/decision blog
	public final static String TYPE_ENGR_BLOG	= "Personal";	// personal logbook blog
	public final static String TYPE_FRUM_BLOG	= "Forum";		// help forum blog
	public final static String TYPE_MTG_BLOG	= "Meeting";	// meeting blog
	public final static String TYPE_NOTE_BLOG	= "Note";		// note
	public final static String TYPE_QUEST_BLOG	= "Quest";		// quest (questionnaire/event)
	public final static String TYPE_ATTMT_BLOG	= "Attachmt";	// attachment comment
	public final static String TYPE_PROJ_PHASE	= "ProjPhase";	// project sub-phase records
	public final static String TYPE_WORKFLOW	= "Workflow";	// project sub-phase records

	public final static String TYPE_ARCHIVE		= "-Archive";	// append to end of type if Archived

	public final static int LRESULT_LENGTH		= 60;			// the length of text shown in 1 line description
	public final static int BUG_LRESULT_LENGTH	= 80;			// the length of text shown in 1 line description

	public final static String TAG_DYNAMIC_BLOG	= "!@";
	public final static String TAG_SHARED_BLOG	= "!#";
	public final static String TAG_INSERT_IMAGE	= "<ins_PRM/>";


	//Private attributes
	private static SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");
	private static String HOST = Util.getPropKey("pst", "PRM_HOST");

	static Logger l = PrmLog.getLog();

    static resultManager manager;
	private static userManager uMgr;
	private static taskManager tkMgr;
	private static projectManager pjMgr;
	private static eventManager evMgr;
	
	static {
		try {
            manager = resultManager.getInstance();
			uMgr = userManager.getInstance();
			tkMgr = taskManager.getInstance();
			pjMgr = projectManager.getInstance();
			evMgr = eventManager.getInstance();
		}
		catch (PmpException e) {}
	}

    /**
     * Constructor for instantiating a new result.
     * @param member An OmsMember representing a result.
     */
    public result(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new result.
     * @param user A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	result(PstUserAbstractObject user, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(user, org, memberName, password);
	}



    /**
     * Constructor for creating a result.  Used by resultManager.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the result.
     */
    result(PstUserAbstractObject user, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(user, org, "");
    }//End Constructor

    /**
     * Constructor for creating a result.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the result.
     */
    result(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }//End Constructor

    /**
     * Constructor for creating a result using a member name.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the result.
     * @param resultMemName The member name for the created result.
     */
    result(PstUserAbstractObject user, OmsOrganization org, String resultMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(user, org, resultMemName, null);
    }//End Constructor

    /**
     * Constructor for creating a result using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the result.
     * @param companyMemberName The member name for the created result.
     */
    result(OmsSession session, OmsOrganization org, String resultMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, resultMemName, null);
    }//End Constructor


    /**
     * Currentyly Not Implemented.
     * Determine whether attribute is settable.
     * @param attributeName Name of attribute.
     */
    private boolean isSetAuthorized(String attributeName)
    {
        return true;

    }//End isSetAuthorized

    /**
     * Set attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, false);
    }//End setAttribute

    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeId The attribute id.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValues);
    }//End setAttribute

    /**
     * Append attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, true);
    }//End appendAttribute

    /**
     * Append attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, true);
	}

    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, false);
	}


    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @param bAppend True if the attribute value is to append to the current value list
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    protected void setAttribute(String attributeName, Object attributeValue, boolean bAppend)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            if(attributeValue instanceof byte[] || attributeValue==null)
            {
                super.setRawData(attributeName, (byte [])attributeValue);
            }
            else
            {
                throw new PmpTypeMismatchException("Data is not of RAW type.");
            }
        }
        else
        {
            super.setData(attributeName, attributeValue, bAppend);	// support appending data
        }

    }//End setAttribute


    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeName The attribute name.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValues))
        {
            throw new PmpTypeMismatchException("Attribute values has an incorrect type.");
        }
        else if(manager.getAttributeType(attributeName)== RAW)
        {
            //Delete raw data value if null
            if(attributeValues == null)
            {
                super.setRawData(attributeName,null);
            }
            else
            {
                throw new PmpUnsupportedTypeException("Raw data with multiple values is not supported.");
            }
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        super.setData(attributeName, attributeValues);

    }//End setAttribute

    /**
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void removeAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeData(attributeName, attributeValue);
        }

    }//End removeAttribute

    /**
     * Get the attribute value.
     * @param attributeId The attribute id.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(int attributeId)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        String attributeName = manager.getAttributeName(attributeId);
        return getAttribute(attributeName);
    }//End getAttribute

    /**
     * Get the attribute value.
     * @param attributeName The attribute name.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(String attributeName)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        if(manager.getAttributeType(attributeName) == RAW)
        {
            byte [] rawResult = super.getRawData(attributeName);
            Object [] finalResult = new Object[1];
            finalResult[0] = rawResult;
            return finalResult;
        }

        if(manager.hasMultipleValues(attributeName))
        {
            return super.getMultipleData(attributeName, manager.getAttributeType(attributeName));
        }
        else
        {
            Object [] finalResult = new Object[1];
            finalResult[0] = super.getSingleData(attributeName, manager.getAttributeType(attributeName));
            return finalResult;
        }

    }//End getAttribute


    protected void delete()
        throws PmpDeleteObjectException
    {
        super.delete();
    }//End delete

    protected void save()
        throws PmpCommitObjectException
    {
        super.save();
    }//End save

    protected boolean refresh()
    {
        return super.refresh();
    }//End refresh

    public void deleteResult(PstUserAbstractObject u)
		throws PmpException
	{
    	// @SWS092806 delete this blog's uploaded attachment objects and remove from index
		attachmentManager attMgr = attachmentManager.getInstance();
		Object [] objArr = getAttribute("AttachmentID");
		for (int i=0; i<objArr.length; i++) {
			if (objArr[i] != null) {
				int aID = Integer.parseInt(objArr[i].toString());
				attachment att = (attachment)attMgr.get(u, aID);
				attMgr.delete(att); // removes from index
			}
		}

		// remove all files here
		String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
		String pathName = repository + File.separator + getObjectId();
		File f = new File(pathName);
		File [] fList = f.listFiles();
		if (fList != null)
		{
			for (int i=0; i<fList.length; i++)
				fList[i].delete();
		}
		f.delete();		// delete the directory

		// delete myself
		manager.delete(this);
	}

    public static void createOneLiner(PstUserAbstractObject pstuser,
    		String idS, String blogIdS, String shortText, String parentIdS, boolean bUpdate)
    	throws PmpException
    {
		int commentNum = 0;
		String S = "";		// plural?

		String lookingId=null;
		if (bUpdate) lookingId = blogIdS;
		else if (parentIdS != null) lookingId = parentIdS;

		int [] ids;
		if (lookingId != null)
		{
			ids = manager.findId(pstuser, "ParentID='" + lookingId + "'");
			commentNum = ids.length;
		}
		if (commentNum > 1) S = "s";

		latest_resultManager lrMgr = latest_resultManager.getInstance();
		latest_result lResultObj = null;
		String s = shortText;
		Date now = new Date();
		String updatorIdS = String.valueOf(pstuser.getObjectId());

		ids = lrMgr.findId(pstuser, "TaskID = '" + idS + "'");		// taskId or bugId
		if (ids.length <= 0)
		{
			// need to create the new latest_result object
			lResultObj = (latest_result)lrMgr.create(pstuser);
			lResultObj.setAttribute("TaskID", idS);		// taskId or bugId
		}
		else
		{
			// retrieve the latest_result object of this task (only one latest result)
			lResultObj = (latest_result)lrMgr.get(pstuser, ids[0]);
			if (parentIdS != null)
			{
				// use the old latest result, simply update the comment num
				s = (String)lResultObj.getAttribute("LastComment")[0];
				s = s.substring(0, s.lastIndexOf(" ..."));
			}
		}
		s += " ... (" + commentNum + " comment" +S+ ")";
		lResultObj.setAttribute("LastComment", s);
		lResultObj.setAttribute("LastUpdatedDate", now);
		lResultObj.setAttribute("LastUpdator", updatorIdS);
		lrMgr.commit(lResultObj);
    }
    
    /**
     * getShortText() takes a plain text string and cut it down to certain length
     * @param u
     * @param stripText
     * @return
     */
    public static String getShortText(PstUserAbstractObject u, String stripText)
    {
		stripText = u.getObjectName() +":: " + stripText;
		int len = stripText.length();
		if (len > result.LRESULT_LENGTH) len = result.LRESULT_LENGTH;
		String shortText = stripText.substring(0,len);
		return shortText;
    }

    public static String displayBlog(
    		PstUserAbstractObject u,
    		PstAbstractObject [] blogList,
    		String type,
    		String idS,							// bugId or taskId: pass to addblog.jsp
    		String idS2,						// not used: bugId or pTaskId: pass to blog_comment.jsp
    		String blogIdS,						// the blog to highlight (bold)
    		int projCoordinatorId,
    		String townIdS,
    		String projIdS,
    		String taskIdS,
    		String aIdS,						// not used: action/decision Id
    		String backPage,
    		boolean isAdmin,
    		boolean isEmail						// for displaying in Email
    		)
    	throws PmpException, UnsupportedEncodingException
    {
    	StringBuffer sBuf = new StringBuffer(8192);
    	resultManager rMgr = manager;

    	SimpleDateFormat df1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEEEEEEE)");
    	SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");
    	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");
    	
    	userinfo.setTimeZone(u, df1);
    	userinfo.setTimeZone(u, df2);
    	userinfo.setTimeZone(u, df3);

    	int selectedBlogId = ( blogIdS!=null ? Integer.parseInt(blogIdS) : 0 );
    	String uidS = String.valueOf(u.getObjectId());

    	Date createDate, commentDate;
    	String creatorIdS;
    	String uname, skypeName, viewS;
    	user aUser;
    	boolean isPersonalBlog = type.equals(TYPE_ENGR_BLOG) || type.equals(TYPE_FRUM_BLOG);

    	String bText, stackName=null;
    	//Object bTextObj;
    	int comNum, blogId;
    	result blog;
    	task tk = null;
    	PstAbstractObject commentObj;
    	
    	boolean isProjectBlogPage = idS==null;

    	sBuf.append("<table width='100%' class='fix_table'>");

    	for (int i = 0; i < blogList.length; i++)
    	{
    		blog = (result)blogList[i];
    		createDate = (Date)blog.getAttribute("CreatedDate")[0];
    		creatorIdS = (String)blog.getAttribute("Creator")[0];
    		try {
    			aUser = (user)uMgr.get(u, Integer.parseInt(creatorIdS));
        		uname = aUser.getFullName();
        		skypeName = (String)aUser.getAttribute("SkypeName")[0];
    		}
    		catch (PmpException e) {
    			// might be a deleted user
    			uname = "inactive user";
    			skypeName = null;
    		}
    		catch (NumberFormatException ee) {
    			uname = "unknown";
    			skypeName = null;
    		}
    		
    		// get stack name for displaying project blogs
    		if (isProjectBlogPage) {
    			idS = blog.getStringAttribute("TaskID");
    			try {
	    			tk = (task)tkMgr.get(u, idS);
	    			stackName = TaskInfo.getTaskStack(u, tk.getPlanTask(u));
    			}
    			catch (PmpException e) {
    				l.error("Failed to get task in result.displayBlog(), probably blog [" + blog.getObjectId()
    						+ "] is on a deleted task [" + idS + "]");
    				continue;
    			}
    			if (Util.isNullOrEmptyString(stackName)) {
    				continue;	// somehow plantask is not there, must be a deleted task
    			}
    		}
    		
    		// might be dynamic blogs
    		StringBuffer tempBuf = new StringBuffer();
    		try {blog = result.parseBlog(u, blog, tempBuf);}
    		catch (PmpException e) {continue;}
    		bText = tempBuf.toString();		// this might just be blog content or customized content
    				
    		/*bTextObj = blog.getAttribute("Comment")[0];
    		bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
    		*/

    		// comments
    		blogId = blog.getObjectId();
    		int [] ids = rMgr.findId(u, "ParentID='" + blogId + "'");
    		comNum = ids.length;

    		// inc ViewBlogNum
    		if ((blogIdS==null && i==0) || selectedBlogId == blogId)
    			viewS = String.valueOf(Util.incAttrNum(rMgr, blog, "ViewBlogNum"));
    		else
    			viewS = Util.getAttrNum(blog, "ViewBlogNum", "1");

    		// DATE line
    		sBuf.append("<tr><td colspan='2'>");
    		sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
    		sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='20'/></td></tr>");
    		sBuf.append("<tr><td width='400' height='20' class='blog_date'><a name="
    				+ blogId + "></a>" + df1.format(createDate) + "</td>");
    		sBuf.append("<td class='plaintext_grey' align='right'>(View by "
    				+ viewS + ")</td>");
    		sBuf.append("</tr>");
    		
    		// when displaying project blog page, idS is null because we don't know
    		// which task we are clicking on
    		if (isProjectBlogPage) {
    			// show task stack name
    			sBuf.append("<tr><td colspan='2'><table cellspacing='0' cellpadding='0'>");
    			sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' width='10'/></td>");
    			sBuf.append("<td class='ptextS1'>Task blog: <a href='blog_task.jsp?projId="
    					+ tk.getStringAttribute("ProjectID")
    					+ "&taskId=" + idS + "'>"
    					+ stackName + "</a></td></tr>");
    			if (comNum > 0) {
    				// display last blog CreatedDate
    				commentObj = rMgr.get(u, ids[comNum-1]);		// get last comment (need sort?)
    				commentDate = (Date)commentObj.getAttribute("CreatedDate")[0];
    				sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' width='10'/></td>");
        			sBuf.append("<td class='ptextS1'><font color='#ee0000'>Last comment on: </font><a href='javascript:showComment("
        					+ blogId + ");'>" + df3.format(commentDate) + "</a>");
    			}
    			sBuf.append("</table></td></tr>");
    		}
       		sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='20'/></td></tr>");
       	    sBuf.append("</table></td></tr>");	// close DATE line table

    		// TEXT
    		sBuf.append("<tr><td colspan='2' class='blog_text'>");
    		sBuf.append(bText + "<p></p></td></tr>");

    		// AUTHOR
    		sBuf.append("<tr><td width='1'><a name='com_" + blogId + "'/><img src='" + HOST + "/i/spacer.gif' width='1' height='3'></td></tr>");
    		sBuf.append("<tr><td colspan='2'><table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>");
    		sBuf.append("<tr><td class='blog_by'>POSTED BY "
    				+ uname.toUpperCase() + " | <font color='#dd8833'>"
    				+ df2.format(createDate) + "</font></td>");

    		// buttons on the bottom right
    		sBuf.append("<td width='250' align='right'>");
    		sBuf.append("<table border='0' width='100%' cellspacing='0' cellpadding='0'><tr>");
    		if (!creatorIdS.equals(uidS))
    		{
    			sBuf.append("<td>");
    			if (skypeName != null)
    				sBuf.append("<a href='skype:" + skypeName + "'>");	// for marketing, now always display icon
    			else
    				sBuf.append("<a href='javascript:alert(\"Sorry, the user " + uname + " has not entered a Skype name.\");'>");
    			sBuf.append("<img src='" + HOST + "/i/skype.gif' border='0'></a>");
    			sBuf.append("</td>");
    		}

    		if (!isEmail) {
    		// EDIT
    		if (isAdmin || creatorIdS.equals(uidS) /*|| managerIdS.equals(uidS)*/)
    		{
    			sBuf.append("<td width='50' align='center'>");
    			sBuf.append("<a class='blog_small' href='" + HOST + "/blog/addblog.jsp?type="
    					+ type + "&id=" + idS + "&update=" + blog.getObjectId()
    					+ "&backPage=" + backPage + "'>EDIT</a></td>");
    		}

    		// DEL
    		if (isAdmin || (projCoordinatorId == u.getObjectId()) ||  creatorIdS.equals(uidS))
    		{
    			sBuf.append("<td width='40' align='center'>");
    			sBuf.append("<a class='blog_small' href='" + HOST + "/blog/delblog.jsp?blogId="
    					+ blogId + "&backPage=" + backPage
    					+ "' onClick='return confirm(\"Are you sure you want to delete this Blog?\")'>DEL</a></td>");
    		}
    		}	// !isEmail

    		// COMMENT
    		sBuf.append("<td align='center'>");
    		if (!isEmail)
	    		sBuf.append("<a class='blog_small' href='javascript:showComment(" + blogId
	    				+ ");'>");
    		if (comNum > 0) {
    			sBuf.append("<font color='#ee0000'>COMMENT (" + comNum + ")</font>");
    		}
    		else {
    			sBuf.append("COMMENT (0)");
    		}
    		if (!isEmail)
    			sBuf.append("</a>");
    		sBuf.append("</td>");

    		String list = "";
    		if (!uidS.equals(creatorIdS)) {
    			list = uidS + "," + creatorIdS;
    		}
    		else
    			list = creatorIdS;

    		if (!isEmail) {
    		// EMAIL
    		sBuf.append("<td width='55' align='center'>");
    		sBuf.append("<a class='blog_small' href='addalert.jsp?list=" + list + "&townId=" + townIdS
    				+ "&projId=" + projIdS + "&taskId=" + taskIdS + "&backPage=" + backPage
    				+ "&id=" + blog.getObjectId() + "&type=blog'>EMAIL</a></td>");
    		}

    		sBuf.append("</tr></table></td>");	// end bottom buttons

    		sBuf.append("</tr></table></td></tr>");
    		sBuf.append("<tr><td colspan='2'><table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>");
    		sBuf.append("<tr><td bgcolor='#bbbbbb' width='100%' height='1'><img src='" + HOST + "/i/spacer.gif' width='1' height='1' border='0'></td>");
    		sBuf.append("</tr></table>");
    		
    		// display comment
    		PstAbstractObject [] commentList = rMgr.get(u, ids);

    		// sort the result by create date.  Display in date order postings first.
    		//Util.sortDate(commentList, "CreatedDate", false);
    		Util.sortById(commentList);		// display older first

    		// add a DIV to show comments and add comment in place
    		sBuf.append("<DIV id='com_" + blogId);
    		if (!isEmail)
    			sBuf.append("' style='display:none;'");
    		sBuf.append("><table width='100%'>");
    		sBuf.append(getBlogComments(u, commentList,
    				String.valueOf(blogId), idS, type, backPage,
    				isPersonalBlog, false, isEmail));
    		sBuf.append("</table></DIV>");

    	}	// end for loop for bloglist

    	sBuf.append("</table>");
    	return sBuf.toString();
    }
    
    public static String getBlogComments(
    		PstUserAbstractObject u,
    		PstAbstractObject [] blogList,		// list of comments
    		String parentBlogIdS,
    		String objIdS,						// bugId, meetingId, taskId, userId
    		String type,
    		String backPage,
    		boolean isPersonalBlog,
    		boolean isGuest,
    		boolean isEmail)					// composing an email
    	throws PmpException, UnsupportedEncodingException
	{
    	return getBlogComments(u, blogList, parentBlogIdS, objIdS, type,
    					backPage, null, isGuest, isGuest, isEmail);
	}

    /**
     * @throws UnsupportedEncodingException 
     * 
     */
    public static String getBlogComments(
    		PstUserAbstractObject u,
    		PstAbstractObject [] blogList,		// list of comments
    		String parentBlogIdS,
    		String objIdS,						// bugId, meetingId, taskId, userId
    		String type,
    		String backPage,
    		String cancelLink,
    		boolean isPersonalBlog,
    		boolean isGuest,
    		boolean isEmail)					// composing an email
    	throws PmpException, UnsupportedEncodingException
    {
    	// list the comments on blog
    	StringBuffer sBuf = new StringBuffer(8192);
    	String s, privateStr, creatorIdS, uname;
    	result blog;
    	user aUser;
    	Date createDate;
    	String bText;
    	Object bTextObj;
    	
    	String myUidS = String.valueOf(u.getObjectId());
    	
    	if (cancelLink == null) cancelLink = "javascript:history.back(-1)";
    	
    	// for personal blog: page owner
    	String ownerName = "";
    	if (isPersonalBlog) {
    		try {
    			user owner = (user)uMgr.get(u, objIdS);
    			ownerName = owner.getFullName();
    		}
    		catch (PmpException e) {}
    	}
    	
    	// get project object for task blog
    	String checkStr = "";
    	if (type.equals(TYPE_TASK_BLOG)) {
    		task tk = (task)tkMgr.get(u, objIdS);
    		project projObj = tk.getProject(u);
			checkStr = projObj.getOption(project.OP_NOTIFY_BLOG)!=null?"checked":"";
    	}
    	
    	// display list of comments
    	for (int i = 0; i < blogList.length; i++)
    	{
    		blog = (result)blogList[i];
    		createDate = (Date)blog.getAttribute("CreatedDate")[0];
    		creatorIdS = (String)blog.getAttribute("Creator")[0];
    		try {
    			aUser = (user)uMgr.get(u, Integer.parseInt(creatorIdS));
        		uname =  aUser.getFullName();
    		}
    		catch (PmpException e) {
    			uname = "inactive user";
    		}

    		// @ECC101608 filter private/personal blog
    		privateStr = "";
    		if (isPersonalBlog)
    		{
    			s = Util2.getAttributeString(blog, "ShareID", ";");
    			if (s.length() > 0)
    			{
    				if (s.indexOf(myUidS) == -1)
    					continue;				// this blog is not shared by this user
    				else
    					privateStr = "(Private message for " + ownerName + " only)&nbsp;&nbsp;&nbsp;";
    			}
    		}

    		bTextObj = blog.getAttribute("Comment")[0];
    		bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
    		bText = bText.replaceAll("\n", "<br>");

    		// DATE
    		userinfo.setTimeZone(u, df);
    		sBuf.append("<tr><td height='50' class='plaintext'>");
    		sBuf.append("<b>" + uname.toUpperCase() + "</b> wrote on <span class='com_date'>"
    				+ df.format(createDate) + "</span>");
    		sBuf.append("<img src='" + HOST + "/i/spacer.gif' width='100' height='1' />");
    		sBuf.append("<span class='plaintext_grey'>" + privateStr + "</span>");
    		sBuf.append("</td></tr>");

    		// TEXT
    		sBuf.append("<tr><td colspan='2' class='blog_text'>");
    		sBuf.append(bText);
    		sBuf.append("</td></tr>");
    		sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' width='1' height='10'></td></tr>");

    		sBuf.append("<tr><td>");
    		sBuf.append("<table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>");
    		sBuf.append("<tr><td bgcolor='#bbbbbb' width='100%' height='1'>");
    		sBuf.append("<img src='" + HOST + "/i/spacer.gif' width='1' height='1' border='0'></td>");
    		sBuf.append("</tr></table></td></tr>");
    	}	// end for loop for bloglist


		if (!isGuest && !isEmail)
		{
			// textarea to add comment
	    	sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' width='1' height='5'></td></tr>");
	
	    	// add comments -->
	    	sBuf.append("<form name='AddCommentForm_" + parentBlogIdS + "' action='../blog/post_addblog.jsp' method='post'>");
	    	sBuf.append("<input type='hidden' name='type' value='" + type + "'>");
	    	sBuf.append("<input type='hidden' name='id' value='" + objIdS + "'>");
	    	sBuf.append("<input type='hidden' name='parentId' value='" + parentBlogIdS + "'>");
	    	sBuf.append("<input type='hidden' name='backPage' value='" + backPage + "'>");

	    	sBuf.append("<input type='hidden' name='comments' value='true'>");
	    	sBuf.append("<tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	    	sBuf.append("<tr><td colspan='2' class='plaintext_blue'>&nbsp;&nbsp;Add Comment:</td></tr>");
	    	sBuf.append("<tr><td width='15'>&nbsp;</td><td width='100%' >");
	    	sBuf.append("<textarea name='logText' rows='8' style='width:95%;'></textarea>");
	    	sBuf.append("</td></tr>");
    		
	    	// allow override send Email to project team
    		if (type.equals(TYPE_TASK_BLOG) || type.equals(TYPE_ACTN_BLOG)) {
    			sBuf.append("<tr><td></td><td class='plaintext_big'>");
    			sBuf.append("<input type='checkbox' name='sendEmail' " + checkStr);
    			if (type.equals(TYPE_TASK_BLOG))
    				sBuf.append(">&nbsp;Send Email notification to team members");
    			else
    				sBuf.append(">&nbsp;Send Email notification to action item responsible members");
    				
    			// I need the following because checkbox returns null in post page if it is uncheck
    			sBuf.append("<input type='hidden' name='overrideSendEmail' value='true'>");
    			
    			sBuf.append("<img src='../i/spacer.gif' width='20' height='1'/>");
    			sBuf.append("<input type='checkbox' name='sendEmailSel' ");
    			sBuf.append("checked>&nbsp;Send Email notification to original author");	// ECC: always checked
    			// I need the following because checkbox returns null in post page if it is uncheck
    			sBuf.append("<input type='hidden' name='overrideSendEmailSel' value='true'>");
    			sBuf.append("</td></tr>");
    			
    			sBuf.append("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
    			sBuf.append("<tr><td></td><td class='plaintext_big'>&nbsp;");
    			sBuf.append("Other emails<img src='../i/spacer.gif' width='10' height='1' />");
    			sBuf.append("<input type='text' value='' name='otherEmail' style='width:84%;'></input>");
    			sBuf.append("</td></tr>");
    			sBuf.append("<tr><td></td><td><img src='../i/spacer.gif' width='83' height='1' />");
    			sBuf.append("<span class='plaintext_grey'>&nbsp;&nbsp;(Enter emails or username, separated by comma)</span>");
    			sBuf.append("</td></tr>");
    		}

    		// blog for MyPage to user (personal)
    		if (ownerName != "")
    		{	
    			sBuf.append("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
    			sBuf.append("<tr><td></td><td class='plaintext_big'>");
    			sBuf.append("<img src='../i/spacer.gif' width='20' height='1' />");
    			sBuf.append("<input type='checkbox' name='private' value='true'>&nbsp;This blog is a private message and is only viewed by <b>"
    					+ ownerName + "</b>");
    			sBuf.append("</td></tr>");
    		}

    		sBuf.append("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");

    		sBuf.append("<tr><td></td><td align='center'>");
    		sBuf.append("<input type='button' class='button_medium' value='Submit' "
    				+ "onClick='javascript:document.AddCommentForm_" + parentBlogIdS + ".submit()'>");
    		sBuf.append("&nbsp;&nbsp;<input type='button' class='button_medium' value='Cancel' "
    				+ "onClick='" + cancelLink + ";'>");
    		sBuf.append("</td></tr></table></td></tr>");
    		sBuf.append("</form>");
		}	// !isGuest && !isEmail
    	// End of add comments
		
		sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='10'/></td></tr>");
		sBuf.append("<tr><td colspan='2'><table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td bgcolor='#bb5555' width='100%' height='1'>");
		sBuf.append("<img src='" + HOST + "/i/spacer.gif' width='1' height='1' border='0'></td>");
		sBuf.append("</tr></table></td></tr>");
    	
    	return sBuf.toString();
    }	// END: getBlogComments()

    /**
    	Strip the text into a short text with no HTML tags.
    	@param text
    	@param len is the length to be returned.
    	@return the string after stripping.
    */
    public static String stripText(String text, int len)
    {
		if (text==null || text.trim().length()<=0)
			return "";

		String stripText = text.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
		if (stripText.length() > len) stripText = stripText.substring(0,len);
		stripText = stripText.replaceAll("&nbsp;", " ");	// replace &nbsp;
		return stripText;
	}
    
    public static void triggerEvent(PstUserAbstractObject me, PstAbstractObject obj, String evtCreatorIdS,
    		String blogText, String bugSynopsis, String blogType,
    		String parentIdS, String blogIdS, String projIdS, String pTaskIdS, String idS,
    		boolean isMyPage, boolean isPrivate)
    	throws PmpException
	{
    	String NODE = Prm.getPrmHost();
    	int ct;
    	int [] ids;
		event evt = null;
		String lnkStr = null;
		int [] sameCircleUidArr = null;		// for forum blog trigger event and send Email
		String s;
		project projObj = null;
		
    	if (evtCreatorIdS != null) {
    		// for Mobile, I need to change the event trigger person
    		me = (PstUserAbstractObject) uMgr.get(me, Integer.parseInt(evtCreatorIdS));
    	}

		
		int myUid = me.getObjectId();
		
		if (projIdS != null) {
			projObj = (project) pjMgr.get(me, Integer.parseInt(projIdS));
		}
		
		//originalText = text;
		blogText = blogText.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
		blogText = blogText.replaceAll("&nbsp;", " ");
		blogText = blogText.replaceAll("  ", " ");				// reduce space
		if (blogText.length() > 100)
		{
			int idx = blogText.indexOf(" ", 100);
			if (idx!=-1 && idx<200)
				blogText = blogText.substring(0, idx);
			else
				blogText = "";
		}

		// add spaces to make event display wrap to newline
		if (blogText.length() > 30) {
			if (blogText.indexOf(' ') == -1) {
				blogText = blogText.replaceAll("/", "/ ");
			}
			if (blogText.indexOf(' ') == -1) {
				blogText = blogText.substring(0, 27) + " " + blogText.substring(27);
			}
		}

		int orgBlogCreatorId = 0;
		user orgBlogCreator = null;
		PstAbstractObject o = null;

		if (parentIdS != null)
		{
			// comment on blog
			o = manager.get(me, parentIdS);	// the parent blog object
			orgBlogCreatorId = Integer.parseInt((String)o.getAttribute("Creator")[0]);
			orgBlogCreator = (user)uMgr.get(me, orgBlogCreatorId);

			lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + parentIdS;

			// create the event
			if (blogType.equals(result.TYPE_TASK_BLOG)) {
				evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PJ_C, null, null, null);
				
				String stackName = TaskInfo.getProjTaskStack(me, (task)tkMgr.get(me, idS));

				s = "<a href='" + NODE + "/project/proj_plan.jsp?projId=" + projIdS + "'>"
						+ stackName + "</a>";
				lnkStr += "&projId=" + projIdS + "&id=" + pTaskIdS + "&type=" + result.TYPE_TASK_BLOG
						+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task
				try {
				PrmEvent.setValueToVar(evt, "var1", s);
				PrmEvent.setValueToVar(evt, "var2", lnkStr);
				}
				catch (PmpException e) {
					System.out.println("error creating event [" + evt.getObjectId() + "]");
				}
			}
			else if (blogType.equals(result.TYPE_BUG_BLOG)) {
				evt = PrmEvent.create(me, PrmEvent.EVT_BLG_BUG_C, null, null, null);

				s = "<a href='" + NODE + "/bug/bug_update.jsp?bugId=" + idS
						+ "'>" + bugSynopsis + "</a>";
				lnkStr += "&projId=" + projIdS + "&id=" + idS + "&type=" + result.TYPE_BUG_BLOG
						+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task
				/*lnkStr = "<blockquote class='bq_com'>" + blogText
						+ "... <a href='" + NODE + "/blog/blog_task.jsp?projId=" + projIdS + "&bugId="
						+ idS + "#com_" + parentIdS + "'>read more & reply</a></blockquote>";*/
				try {
					PrmEvent.setValueToVar(evt, "var1", s);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
				}
				catch (PmpException e) {
					System.out.println("error creating event [" + evt.getObjectId() + "]");
				}
			}
			else if (blogType.equals(result.TYPE_ACTN_BLOG)) {
				evt = PrmEvent.create(me, PrmEvent.EVT_BLG_AC_C, null, null, null);

				s = "<a href='" + NODE + "/project/proj_action.jsp?projId=" + projIdS
						+ "&aid=" + idS
						+ "'>" + projObj.getDisplayName() + "</a>";

				/*lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
						+ "&projId=" + projIdS + "&id=" + idS + "&type=" + result.TYPE_ACTN_BLOG
						+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";*/		// this link is used by both original blog or comment on task
				
				lnkStr += "&projId=" + projIdS + "&id=" + idS + "&type=" + result.TYPE_ACTN_BLOG
						+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";
								
				/*lnkStr = "<blockquote class='bq_com'>" + blogText
						+ "... <a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS
						+ "&aid=" + idS + "&showEd=1"
						+ "'>read more & reply</a></blockquote>";*/

				PrmEvent.setValueToVar(evt, "var1", s);
				PrmEvent.setValueToVar(evt, "var2", lnkStr);
			}
			// all others
			else {
				evt = PrmEvent.create(me, PrmEvent.EVT_BLG_COMMENT, null, null, null);
				lnkStr += "&id=" + o.getAttribute("TaskID")[0] + "&type=Personal#reply'>read more & reply</a></blockquote>";
				PrmEvent.setValueToVar(evt, "var1", lnkStr);
			}

			s = orgBlogCreator.getFullName();
			evt.setAttribute("AlertMessage", ((String)evt.getAttribute("AlertMessage")[0]).replaceFirst("to your", "to "+ s + "\\'s"));
			evMgr.commit(evt);

	    	
			if (Prm.isPRM()) {
				// send to project members
				ids = Util2.toIntArray(projObj.getAttribute("TeamMembers"));
			}
			else {
		    	// stack the event to all of the commentors
		    	ids = manager.findId(me, "ParentID='" + parentIdS + "'");
		    	int [] ids1 = new int[ids.length];
		    	for (int i=0; i<ids.length; i++)
		    	{
		    		try {ids1[i] = Integer.parseInt((String)manager.get(me, ids[i]).getAttribute("Creator")[0]);}
		    		catch (PmpException e) {ids1[i] = -99999; continue;}
		    	}
	
				// stack the event to the original blog author and myself
		    	ids = new int [2];
		    	ids[0] = orgBlogCreatorId;				// include creator of the original blog
		    	ids[1] = myUid;
		    	ids = Util2.mergeIntArray(ids, ids1);
			}


	    	ct = PrmEvent.stackEvent(me, ids, evt);
	    	l.info("*** " + myUid + " triggered Event [" + evt.getStringAttribute("Type")
	    			+ "] to " + ct + " users for comment blog.");
		}
		
		// top blog; not comment
		else
		{
			// not a comment: A. forum page; B. other's page; C. my page; D. meeting; E. circle taskBlog
			if (!blogType.equals(result.TYPE_TASK_BLOG)
					&& !blogType.equals(result.TYPE_MTG_BLOG)
					&& !blogType.equals(result.TYPE_BUG_BLOG)
				)
				lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../ep/my_page.jsp?uid=" + idS
					+ "#" + blogIdS + "'>read more & reply</a></blockquote>";

			if (!isMyPage)
			{
				// tell the page owner I have posted on his page
				if (blogType.equals(result.TYPE_FRUM_BLOG))
				{
					// A. circle blog
					//PrmEvent.checkCleanMaxEvent(me,
					//		"Type='" + PrmEvent.EVT_BLG_CIR + "' && Creator='" + myUid
					//		+ "' && TownID='" + idS + "'", 0);
					if (idS != null)
					{
						evt = PrmEvent.create(me, PrmEvent.EVT_BLG_CIR, null, idS, null);
						PrmEvent.setMtgCircleToVar(me, evt, "var1");
						PrmEvent.setValueToVar(evt, "var2", lnkStr);
						sameCircleUidArr = uMgr.findId(me, "Towns=" + idS);
						ct = PrmEvent.stackEvent(me, sameCircleUidArr, evt);
				    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_CIR + "] to " + ct + " users.");
					}
				}
				else if (blogType.equals(result.TYPE_MTG_BLOG))
				{
					//PrmEvent.createTriggerEvent(me, PrmEvent.EVT_BLG_POST, idS, (String)obj.getAttribute("TownID")[0], null);
					lnkStr = "<MTG/><br>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId="
						+ blogIdS + "&type=Meeting&id=" + idS + "'>read more & reply</a>";
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_POST, idS, (String)obj.getAttribute("TownID")[0], null);
				    if (evt != null)
				    {
						PrmEvent.setValueToVar(evt, "var2", lnkStr);
					    PrmEvent.trigger(me, evt);
				    }
				}
				else if (blogType.equals(TYPE_QUEST_BLOG))
				{
					// <MTG/> will be replaced when calling Util2.displayQuestLink() in OmfEventAjax.
					lnkStr = "<MTG/><br>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId="
						+ blogIdS + "&type=Quest&id=" + idS + "'>read more & reply</a>";
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_QUEST, idS, (String)obj.getAttribute("TownID")[0], null);
				    if (evt != null)
				    {
						PrmEvent.setValueToVar(evt, "var1", lnkStr);
					    PrmEvent.trigger(me, evt);
				    }
				}
				else if (blogType.equals(TYPE_PROJ_BLOG)) {
					lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
							+ "&projId=" + projIdS + "&type=" + TYPE_PROJ_BLOG
							+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task

					s = (String)projObj.getAttribute("TownID")[0];
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PROJ, null, s, null);
					
					String temp = "<a href='" + NODE + "/project/proj_plan.jsp?projId=" + projIdS+ "'>"
							+ projObj.getDisplayName() + "</a>";
					PrmEvent.setValueToVar(evt, "var1", temp);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
				}
				else if (blogType.equals(TYPE_TASK_BLOG))
				{
					// for OMF, circle project task blog
					// the link to blog_comment.jsp is built above
					lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
								+ "&projId=" + projIdS + "&id=" + pTaskIdS + "&type=" + result.TYPE_TASK_BLOG
								+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task

					s = (String)projObj.getAttribute("TownID")[0];
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PROJ, null, s, null);
					
					String stackName = TaskInfo.getProjTaskStack(me, (task)tkMgr.get(me, idS));
					String temp = "<a href='" + NODE + "/project/proj_plan.jsp?projId=" + projIdS+ "'>"
							+ stackName + "</a>";
					PrmEvent.setValueToVar(evt, "var1", temp);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
					
					if (Prm.isPRM()) {
						// send to project memebers
						ids = Util2.toIntArray(projObj.getAttribute("TeamMembers"));
					}
					else {
						ids = uMgr.findId(me, "Towns=" + s);
					}
					ct = PrmEvent.stackEvent(me, ids, evt);
			    	l.info("*** " + myUid + " triggered Event [" + PrmEvent.EVT_BLG_PROJ + "] to "
			    			+ ct + " users for project (" + projIdS + ") blog.");
				}
				else if (blogType.equals(result.TYPE_BUG_BLOG)) {
					String temp = "<a href='" + NODE + "/bug/bug_update.jsp?bugId=" + idS
							+ "'>" + bugSynopsis + "</a>";
					/*lnkStr = "<blockquote class='bq_com'>" + blogText
							+ "... <a href='" + NODE + "/blog/blog_task.jsp?projId=" + projIdS + "&bugId="
							+ idS + "#" + blogIdS + "'>read more & reply</a></blockquote>";*/

					lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
							+ "&projId=" + projIdS + "&id=" + idS + "&type=" + result.TYPE_BUG_BLOG
							+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task

					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_BUG, projIdS, idS, null);

					PrmEvent.setValueToVar(evt, "var1", temp);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
					ids = Util2.toIntArray(projObj.getAttribute("TeamMembers"));
					ct = PrmEvent.stackEvent(me, ids, evt);
			    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_BUG + "] to "
			    			+ ct + " users for bug (" + idS + ") blog.");
				}
				else if (blogType.equals(result.TYPE_ACTN_BLOG)) {
					// .../blog/blog_task.jsp?projId=68621&aid=69475
					/*lnkStr = "<blockquote class='bq_com'>" + blogText
							+ "... <a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS
							+ "&aid=" + idS + "&showEd=1"
							+ "'>read more & reply</a></blockquote>";*/

					lnkStr = "<blockquote class='bq_com'>" + blogText + "... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
							+ "&projId=" + projIdS + "&id=" + idS + "&type=" + result.TYPE_ACTN_BLOG
							+ "&blogNum=" + blogIdS + "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task

					s = (String)projObj.getAttribute("TownID")[0];
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_ACTN, null, s, null);
					// .../project/proj_action.jsp?projId=68621&aid=12345
					String temp = "<a href='" + NODE + "/project/proj_action.jsp?projId=" + projIdS
							+ "&aid=" + idS + "'>"
							+ projObj.getDisplayName() + "</a>";
					PrmEvent.setValueToVar(evt, "var1", temp);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
					if (Prm.isPRM()) {
						// send to project memebers
						ids = Util2.toIntArray(projObj.getAttribute("TeamMembers"));
					}
					else {
						ids = uMgr.findId(me, "Towns=" + s);
					}
					ct = PrmEvent.stackEvent(me, ids, evt);
			    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_ACTN + "] to "
			    			+ ct + " users for project (" + projIdS + ") action (" + idS + ") blog.");
				}
				else
				{
					// B. blog on some individual's page
					// 1. tell the owner about it
					//PrmEvent.checkCleanMaxEventOnStack(me,
					//		"Type='" + PrmEvent.EVT_BLG_PAGE1 + "' && Creator='" + myUid + "'",
					//		0, idS);	// unstack page1 event on owner's stack from me
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PAGE1, null, null, null);
					PrmEvent.setValueToVar(evt, "var1", lnkStr);
					PrmEvent.stackEvent(me, Integer.parseInt(idS), evt);
			    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_PAGE1 + "] to [" + idS + "]");

					// 2. tell owner's friend that I have posted on his page
					if (!isPrivate)
					{
						user u = (user)uMgr.get(me, Integer.parseInt(idS));
						s = u.getFullName();
						PrmEvent.checkCleanMaxEvent(me,
								"Type='" + PrmEvent.EVT_BLG_PAGE2 + "' && Creator='" + myUid
									+ "' && AlertMessage='% on " + s + "%'", 0);	// remove all old
						evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PAGE2, null, null, null);
						PrmEvent.setValueToVar(evt, "var1", s);		// on John Smith's page
						PrmEvent.setValueToVar(evt, "var2", lnkStr);
						ct = PrmEvent.stackEvent(me, Util2.toIntArray(u.getAttribute("TeamMembers")), evt);
				    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_PAGE2 + "] to [" + idS + "]'s " + ct + " friends");
					}
				}
			}
			else
			{
				// C. I am posting on my own page, tell my friends
				//PrmEvent.checkCleanMaxEvent(me,
				//		"Type='" + PrmEvent.EVT_BLG_PAGE3 + "' && Creator='" + myUid
				//			+ "' && AlertMessage='% on his/her own page%'", 0);	// remove all old
				if (!isPrivate)
				{
					evt = PrmEvent.create(me, PrmEvent.EVT_BLG_PAGE3, null, null, null);
					PrmEvent.setValueToVar(evt, "var1", lnkStr);
					ct = PrmEvent.stackEvent(me, Util2.toIntArray(me.getAttribute("TeamMembers")), evt);
			    	l.info(myUid + " triggered Event [" + PrmEvent.EVT_BLG_PAGE3 + "] to [" + myUid + "]'s " + ct + " friends");
				}
			}
		}
	}	// END: triggerEvent()
    
    public static result parseBlog(PstUserAbstractObject me, result blogObj, StringBuffer retBuf)
    	throws PmpException
    {
		String s;
		int blogId = 0;
		
		try {
			Object bTextObj = blogObj.getAttribute("Comment")[0];
			String bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");

			// Shared blog
			if (bText.startsWith(TAG_SHARED_BLOG)) {
				
				// shared blog: only contains a blog ID
	
				// get original blog poster
				s = (String) blogObj.getAttribute("Creator")[0];
				user bUser = (user)uMgr.get(me, Integer.parseInt(s));
				String creatorFullName = bUser.getFullName();
				
				s = bText.substring(2);				// skip !#
				
				blogId = Integer.parseInt(s);
				blogObj = (result) manager.get(me, blogId);		// switch to the shared blog
				
				s = (String)blogObj.getAttribute("Type")[0];
				String sharedTownName = "private";
				if (s.equals(result.TYPE_FRUM_BLOG)) {
					s = (String) blogObj.getAttribute("TaskID")[0];
					sharedTownName = townManager.getTownName(me, s);
				}
				
				// get blog content from the real one
				bTextObj = blogObj.getAttribute("Comment")[0];
				bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
				
				// customized it
				retBuf.append("<font color='#dd8833'>(Blog shared by ");
				retBuf.append(creatorFullName);
				retBuf.append(" from <b>" + sharedTownName + "</b>)</font></P>");
				retBuf.append(bText);
			}
			
			// dynamic blog
			// contains text and taskIDs
			else if (bText.startsWith(TAG_DYNAMIC_BLOG)) {
				bText = bText.substring(2);				// skip !@
				
				// replace references to blog by corresponding blog text
				int i, idx, len, bTextIdx=0;
				int [] ids;
				String tidS, temp;
				char c;					// extract the blogID
				PstAbstractObject bObj;

				while ((idx = bText.indexOf(TAG_SHARED_BLOG)) != -1) {
					retBuf.append(bText.substring(bTextIdx, idx));		// copy up to the shared tag
					
					// extract the shared blog
					idx += 2;
					bTextIdx = idx;
					len = bText.length();
					tidS = "";

					for (i=0; i<len; i++) {
						c = bText.charAt(i);
						if (c<'0' || c>'9')
							break;
						tidS += c;
						bTextIdx++;
					}
					
					// from taskID, extract the latest task blog
					ids = manager.findId(me, "TaskID='" + tidS, 1);		// it will get the latest
					if (ids.length <= 0)
						continue;
					
					bObj = manager.get(me, ids[0]);
					bTextObj = bObj.getAttribute("Comment")[0];
					temp = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
					
					retBuf.append(temp);
					retBuf.append("</p>");
				}	// END: while there is dynamic task-blog tag
				
				// copy the last portion of text
				retBuf.append(bTextIdx);
			}
			
			// regular blog
			else {
				retBuf.append(bText);
			}
		}
		catch (Exception e) {
			System.out.println("Failed to get shared blog [" + blogId + "]");
			throw new PmpException("Failed to get shared blog [" + blogId + "] in result.class");
		}
		
    	return blogObj;
    }


}//End class result
