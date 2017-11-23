
//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   attachment.java
//  Author: FastPath CodeGen Engine
//  Date:   06-09-06
//  Description:
//		Implementation of attachment class
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// attachment.java : implementation of the attachment class
//

package oct.codegen;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.filechooser.FileSystemView;

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
import util.PrmLog;
import util.StringUtil;
import util.Util;

/**
*
* <b>General Description:</b>  attachment extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "attachment" organization.
*
* The attachment class provides a facility to modify data of an existing attachment object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.attachmentManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class attachment extends PstAbstractObject

{
	// Public constants
	public static final int	DEFAULT_SEC_LEVEL	= 0;
	
	// the type of object this file is associated with
	public static final String	TYPE_PROJECT		= "project";
	public static final String	TYPE_TASK			= "task";
	public static final String	TYPE_BUG			= "bug";
	public static final String	TYPE_MEETING		= "meeting";
	public static final String	TYPE_FOLDER			= "folder";			// to support shared folder
	public static final String	TYPE_B_TASK			= "blog-task";
	public static final String	TYPE_B_BUG			= "blog-bug";
	public static final String	TYPE_B_ACTION		= "blog-action";
	public static final String	TYPE_B_PERSONAL		= "blog-personal";
	public static final String	TYPE_B_FORUM		= "blog-forum";
	
	// DB Attributes
	public static final String LOCATION = "Location";
    //Private attributes

	static private FileSystemView fsv = FileSystemView.getFileSystemView();
	static private Map<String,String> iconCache = new HashMap<String,String>();
	static private String filePath = Util.getPropKey("pst", "SHOW_FILE_PATH");
	static private String URLfilePath = Util.getPropKey("pst", "URL_FILE_PATH");

	static protected Logger l = PrmLog.getLog();


    static attachmentManager manager;

    /**
     * Constructor for instantiating a new attachment.
     * @param member An OmsMember representing a attachment.
     */
    public attachment(OmsMember member)
    {
        super(member);
        try
        {
            manager = attachmentManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting attachmentManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new attachment.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	attachment(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a attachment.  Used by attachmentManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the attachment.
     */
    attachment(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = attachmentManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting attachmentManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a attachment.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the attachment.
     */
    attachment(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = attachmentManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting attachmentManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a attachment using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the attachment.
     * @param attachmentMemName The member name for the created attachment.
     */
    attachment(PstUserAbstractObject userObj, OmsOrganization org, String attachmentMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, attachmentMemName, null);
        try
        {
          manager = attachmentManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting attachmentManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a attachment using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the attachment.
     * @param companyMemberName The member name for the created attachment.
     */
    attachment(OmsSession session, OmsOrganization org, String attachmentMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, attachmentMemName, null);
        try
        {
           manager = attachmentManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting attachmentManager instance.");
        }
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
    
    // getFileName(): only returns the filename without the path info
    public String getFileName()
    	throws PmpException
    {
    	String name = (String)getAttribute("Name")[0];
    	String type = (String)getAttribute("Type")[0];
    	
    	if (type!=null && type.equals(TYPE_FOLDER) && name!=null)
    		return name;			// the file is on external server and filename is stored in Name attribute.  e.g. Google

    	if (name == null)
    		name = (String)getAttribute("Location")[0];
    	if (name==null || name.length()<=0) return null;
    	int idx;
    	if ((idx=name.lastIndexOf("/")) != -1) {
    		name = name.substring(idx+1);
    	}
    	return name;
    }
    
    public File getFile()
    {
    	File fObj = null;
    	try {
	    	String loc = getStringAttribute(LOCATION);
	    	if (!Util.isAbsolutePath(loc)) {
	    		loc = Prm.getUploadPath() + loc;
	    	}
			fObj = new File(loc);
    	}
    	catch (PmpException e) {
    		l.error("attachment.getFile(): failed to get attachment file.");
    	}
		return fObj;
    }
    
    public long size()
    {
    	File fObj;
    	long size = -1;
    	
		fObj = getFile();
		if (fObj!=null && fObj.exists()) {
			size = fObj.length();
		}
    	return size;
    }
    
    // getOwnerDisplayName(): return the owner's FirstName and the LastName initial
    public String getOwnerDisplayName(PstUserAbstractObject u)
    {
    	String uname;
		try
		{
			user o = (user) userManager.getInstance().get(u, Integer.parseInt((String)getAttribute("Owner")[0]));
			//uname = o.getFullName();
			uname = (String)o.getAttribute("FirstName")[0];
			if (uname == null) uname = "-";
		}
		catch (Exception e) {uname = "-";}
    	return uname;
    }
    
    // called for meeting attachment to set or unset the attachment's authorized access list
    // Public meeting attachment can be accessed by all users
    // Private meeting attachment only accessed by invited attendees
    public void setAuthorizedList(meeting mtgObj)
    	throws PmpException
	{
		setAttribute("TeamMembers", null);		// initialize to allow all to access
	   	String mtgType = (String)mtgObj.getAttribute("Type")[0];
    	if (mtgType==null || mtgType.equals(meeting.PRIVATE))
    	{
    		// Private meeting: get all meeting invited attendees and authorized the attachment to them
    		Object [] oArr = mtgObj.getAttribute("Attendee");
    		String s;
    		if (oArr[0] == null) return;	// no attendee: should not happen
    		for (int i=0; i<oArr.length; i++)
    		{
    			s = (String)oArr[i];
    			this.appendAttribute("TeamMembers", new Integer(s.substring(0,s.indexOf(meeting.DELIMITER))));
    		}
    	}
		manager.commit(this);
		return;
	}
    
    /**
     */
    public boolean isGoogle()
    {
    	try {
    		String loc = getStringAttribute("Location");
    		if (loc != null) {
    			loc = loc.toLowerCase();
    			return loc.startsWith("http") && loc.contains("google.com");
    		}
    	}
    	catch (PmpException e) {}
    	return false;    	
    }
    
    /**
      */
    public String getIconURL()
    	throws PmpException, IOException
    {
    	String ext = (String)getStringAttribute("FileExt");
    	if (StringUtil.isNullOrEmptyString(ext)) return null;
    	
    	ext = ext.toLowerCase();
    	String url = iconCache.get(ext);
    	if (url == null) {
        	String fName = "ICON_" + ext + ".gif";
        	File fObj = new File(filePath + "/" + fName);
        	if (!fObj.exists()) {
        		// create the icon file
        		ImageIcon ic = (ImageIcon) fsv.getSystemIcon(getFile());
        		if (ic == null) return null;
        		
        		BufferedImage image = new BufferedImage(
            			ic.getIconWidth(), ic.getIconHeight(), BufferedImage.TYPE_INT_ARGB);
        		Graphics2D g = image.createGraphics();
        		g.drawImage(ic.getImage(), 0, 0, null);
        		g.dispose();
        		ImageIO.write(image, "gif", fObj);
        	}

        	url = URLfilePath + "/" + fName;
        	iconCache.put(ext, url);
    	}
    	return url;
    }
    
    ////////////////////////////////////////////////////////

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





	public String getProjectPath(PstUserAbstractObject uObj)
		throws PmpException
	{
		// return the path project >> task including URL to caller.  If there is no task associated to this attachment,
		// then just return project name
		
		
		// project name
		String pjIdS = getStringAttribute("ProjectID");
		if (pjIdS == null) return null;
		project pjObj = (project) projectManager.getInstance().get(uObj, Integer.parseInt(pjIdS));
		String projName = pjObj.getDisplayName();

		// try to locate task
		int taskId = 0;
		String taskName = null;
		taskManager tMgr = taskManager.getInstance();
		int [] ids = tMgr.findId(uObj, "AttachmentID='" + getObjectId() + "'");
		if (ids.length >= 1) {
			// should be exactly one, use the first one
			taskId = ids[0];
			task tObj = (task) tMgr.get(uObj, taskId);
			taskName = tObj.getTaskName(uObj);
		}
		
		String linkS;
		String pathStr = projName;
		if (taskName != null) {
			// show projName >> taskName and link to task management page
			pathStr += " >> " + taskName;			// projName >> taskName
			linkS = Prm.getPrmHost() + "/project/task_update.jsp?projId=" + pjIdS + "&taskId=" + taskId;
		}
		else {
			// show projName only and link to proj top page
			linkS = Prm.getPrmHost() + "/project/proj_top.jsp?projId=" + pjIdS;
		}
		
		pathStr = "<a href='" + linkS + "'>" + pathStr + "</a>";
		return pathStr;
	}

}//End class attachment
