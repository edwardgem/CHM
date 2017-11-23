
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
//  File:   bug.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of bug class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// bug.java : implementation of the bug class
//

package oct.codegen;
import java.io.File;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.log4j.Logger;

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
import util.PrmLog;
import util.Util;

/**
*
* <b>General Description:</b>  bug extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "bug" organization.
*
* The bug class provides a facility to modify data of an existing bug object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.bugManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class bug extends PstAbstractObject

{
	// bug state constants
	public static final String OPEN		= "new";
	public static final String ACTIVE	= "assigned";
	public static final String ANALYZED	= "resolved";
	public static final String FEEDBACK	= "verified";
	public static final String CLOSE	= "closed";
	public static final String [] STATE_ARRAY	= {OPEN, ACTIVE, ANALYZED, FEEDBACK, CLOSE};

	// bug class/type
	public static final String CLASS_ISSUE	= "issue";
	public static final String CLASS_DS		= "design-bug";
	public static final String CLASS_PS		= "process-bug";
	public static final String CLASS_HW		= "hw-bug";
	public static final String CLASS_SW		= "sw-bug";
	public static final String CLASS_DOC	= "doc-bug";
	public static final String CLASS_SP		= "support";
	public static final String CLASS_CH		= "change-request";
	public static final String [] CLASS_ARRAY	= {CLASS_ISSUE, CLASS_DS, CLASS_PS, CLASS_HW,
		CLASS_SW, CLASS_DOC, CLASS_SP, CLASS_CH};

	// bug status reason
	public static final String REA_FIX		= "fixed";
	public static final String REA_MSTK		= "mistaken";
	public static final String REA_OBS		= "obsolete";
	public static final String REA_DUP		= "duplicate";
	public static final String REA_CNREP	= "cannot-reproduce";
	public static final String REA_NOTBUG	= "not-a-bug";
	public static final String [] REA_ARRAY = {REA_FIX, REA_MSTK, REA_OBS,
		REA_DUP, REA_CNREP, REA_NOTBUG};

	// bug priority
	public static final String PRI_LOW		= "low";
	public static final String PRI_MED		= "medium";
	public static final String PRI_HIGH		= "high";
	public static final String [] PRI_ARRAY	= {PRI_LOW, PRI_MED, PRI_HIGH};

	// bug severity
	public static final String SEV_NCR		= "non-critical";
	public static final String SEV_SER		= "serious";
	public static final String SEV_CRI		= "critical";
	public static final String [] SEV_ARRAY	= {SEV_NCR, SEV_SER, SEV_CRI};
	public static final String SEV_SCRUM	= "scrum";

	// static attributes
	public static String [] BUG_CATEGORY_ARRAY = initCategory();

	public static String ATTR_DESC			= "Description";

    //Private attributes
	private static SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");

	static Logger l = PrmLog.getLog();
    static bugManager manager;


    /**
     * Constructor for instantiating a new bug.
     * @param member An OmsMember representing a bug.
     */
    public bug(OmsMember member)
    {
        super(member);
        try
        {
            manager = bugManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting bugManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new bug.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	bug(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a bug.  Used by bugManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the bug.
     */
    bug(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = bugManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting bugManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a bug.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the bug.
     */
    bug(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = bugManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting bugManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a bug using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the bug.
     * @param bugMemName The member name for the created bug.
     */
    bug(PstUserAbstractObject userObj, OmsOrganization org, String bugMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, bugMemName, null);
        try
        {
          manager = bugManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting bugManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a bug using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the bug.
     * @param companyMemberName The member name for the created bug.
     */
    bug(OmsSession session, OmsOrganization org, String bugMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, bugMemName, null);
        try
        {
           manager = bugManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting bugManager instance.");
        }
    }//End Constructor


    /**
     * Currently Not Implemented.
     * Determine whether attribute is set-able.
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
    }//End setAttribute

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

    private static String [] initCategory()
    {
    	String s = Util.getPropKey("bringup", "BUG_CATEGORY");
    	String [] sa = s.split(";");
    	String [] catArr = new String[sa.length];
    	for (int i=0; i<sa.length; i++)
    	{
    		catArr[i] = sa[i].trim();
    	}
    	return catArr;
    }

    public void deleteBug(PstUserAbstractObject u)
    	throws PmpException
    {
		// delete this bug (itself) and remove all its blogs and uploaded files

		// remove blog and the associated comments
		resultManager rMgr = resultManager.getInstance();
		result rObj = null;
		int [] ids = rMgr.findId(u, "TaskID='" + getObjectId() + "'");
		for (int i=0; i<ids.length; i++)
		{
			// delete all comments associated to this blog
			int [] ids1 = rMgr.findId(u, "ParentID='" + ids[i] + "'");
			for (int j=0; j<ids1.length; j++)
			{
				rMgr.delete(rMgr.get(u, ids1[j])); // delete the comments to the blog
			}
			//rMgr.delete(rMgr.get(u, ids[i]));
			rObj = (result) rMgr.get(u, ids[i]); // @SWS092806 delete the parent blog
			rObj.deleteResult(u);
		}

		// delete attachment objects and remove from index
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

	/**
		Append a comment short text to the history record of this bug
		in the Description attribute.  This call will commit at the end.
	 	@throws UnsupportedEncodingException 
	 */
	public void addCommentHistory(PstUserAbstractObject u, String bugShortText)
		throws PmpException, UnsupportedEncodingException
	{
		String authorName = ((user)u).getFullName();
		String bText = "";
		Object bTextObj = this.getAttribute("Description")[0];
		if (bTextObj != null)
			try	{
				bText = new String((byte[])bTextObj, "utf-8");				
			}catch (java.io.UnsupportedEncodingException e){
			}

		userinfo.setTimeZone(u, df);
		String nowS = df.format(new Date());
		String s = "<font color='#003399'><b>" + authorName
						+ "</b> wrote on " + nowS + ":</font><br>";
		bText = s + bugShortText + " ..." + "<br><br>" + bText;
		this.setAttribute("Description", bText.getBytes("utf-8"));			

		manager.commit(this);		// save to disk
	}

	/**
		Append a system history (RED) record to this bug in the Description
		attribute. This call will not commit.  Callers may call this multiple
		of times and then explicitly commit the bug object.
	 *	@throws UnsupportedEncodingException 
	 */
	public void appendSystemHistory(PstUserAbstractObject u, String sysText)
		throws PmpException, UnsupportedEncodingException
	{
		String authorName = ((user)u).getFullName();
		String bText = "";
		Object bTextObj = this.getAttribute("Description")[0];
		if (bTextObj != null)
			bText = new String((byte[])bTextObj, "utf-8");

		String nowS = df.format(new Date());
		String s = "<font color='#aa0000'>" + sysText
					+ " by " + authorName + " on " + nowS + "</font><p>";
		bText = s + bText;
		this.setAttribute("Description", bText.getBytes("UTF-8"));
	}


	/**
		Append a history record to this bug in the Description attribute.
		This call will not commit.  Callers may call this multiple of
		times and then explicitly commit the bug object.
	 	@throws UnsupportedEncodingException 
	 */
	public void appendHistory(String text)
		throws PmpException, UnsupportedEncodingException
	{
		String bText = "";
		Object bTextObj = this.getAttribute("Description")[0];
		if (bTextObj != null)
			bText = new String((byte[])bTextObj, "utf-8");

		String nowS = df.format(new Date());
		String s = "<font color='#003399'>" + text + " on " + nowS + "</font><p>";
		bText = s + bText;
		this.setAttribute("Description", bText.getBytes("UTF-8"));
	}

}//End class bug
