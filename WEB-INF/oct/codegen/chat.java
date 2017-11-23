//
//  Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   chat.java
//  Author: FastPath CodeGen Engine
//  Date:   11/15/2007
//  Description:
//		Implementation of chat class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// chat.java : implementation of the chat class
//

package oct.codegen;
import java.io.File;

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
import util.Prm;
import util.StringUtil;
import util.Util;
import util.Util2;

/**
*
* <b>General Description:</b>  chat extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "chat" organization.
*
* The chat class provides a facility to modify data of an existing chat object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.chatManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class chat extends PstAbstractObject

{
	public static final String OPT_SILENCE 		= "Silence";			// option Silence:12345;39414

    //Private attributes

	private static final String ICON_FILE_PATH	= Util.getPropKey("pst", "ICON_FILE_PATH") + File.separator;
	private static final String ICON_DEFAULT	= Util.getPropKey("pst", "DEFAULT_ICON");
	private static final String ICON_URL		= Util.getPropKey("pst", "ICON_URL");



    static chatManager manager;
    static userManager uMgr;
    static PstUserAbstractObject jwu;
    
    static {
        try {
            manager = chatManager.getInstance();
            uMgr = userManager.getInstance();
            jwu = Prm.getSpecialUser();
        }
        catch(PmpException pe) {
            //throw new PmpInternalException("Error getting chatManager instance.");
        }
    }

    /**
     * Constructor for instantiating a new chat.
     * @param member An OmsMember representing a chat.
     */
    public chat(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new chat.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	chat(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a chat.  Used by chatManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the chat.
     */
    chat(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = chatManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting chatManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a chat.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the chat.
     */
    chat(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = chatManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting chatManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a chat using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the chat.
     * @param chatMemName The member name for the created chat.
     */
    chat(PstUserAbstractObject userObj, OmsOrganization org, String chatMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, chatMemName, null);
        try
        {
          manager = chatManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting chatManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a chat using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the chat.
     * @param companyMemberName The member name for the created chat.
     */
    chat(OmsSession session, OmsOrganization org, String chatMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, chatMemName, null);
        try
        {
           manager = chatManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting chatManager instance.");
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

    /**
     * get the name of this chat and removed the leading '@' sign
     * @return
     * @throws PmpException
     */
    public String getName()
    	throws PmpException
    {
    	// for non-project chat and attendee==2, return the two persons' name
    	String chatName = getStringAttribute("Name");
    	if (chatName != null && chatName.charAt(0) == '@')
    		chatName = chatName.substring(1); // remove the leading '@'
    	return chatName;
    }
    
    /**
     * get chat name but if it is a two people Any Chat then return the name of the other person
     * @param requesterId
     * @return
     * @throws PmpException
     */
    public String getName(int requesterId)
    	throws PmpException
	{
    	// for non-project chat and attendee==2, return the other person's name
    	if (getStringAttribute("ProjectID") != null
    			|| getAttribute("Attendee").length != 2)
    		return getName();

    	// now extract the attendee
    	String chatName = null;
    	Object [] attendeeArr = getAttribute("Attendee");
    	int id = Integer.parseInt((String) attendeeArr[0]);		// want this name?
    	if (id == requesterId)
    		id = Integer.parseInt((String) attendeeArr[1]);		// want this person's name
    	
    	user u = (user)uMgr.get(jwu, id);
    	chatName = u.getFullName();
    		
    	return chatName;
	}

    /**
     * retrieve the chat icon file URL to be displayed.
     * For two-people chat, get the other person's image
     * @param requesterId	the user id of the person requesting for chat Icon
     * @return
     * @throws PmpException
     */
	public String getChatIcon(int requesterId)
		throws PmpException
	{
    	if (getStringAttribute("ProjectID") != null
    			|| getAttribute("Attendee").length != 2)
    		return getChatIcon();
    	
		// get the other person's icon file
    	Object [] attendeeArr = getAttribute("Attendee");
    	int id = Integer.parseInt((String) attendeeArr[0]);		// want this name?
    	if (id == requesterId)
    		id = Integer.parseInt((String) attendeeArr[1]);		// want this person's name

    	PstAbstractObject u = uMgr.get(jwu, id);
    	return Util2.getPicURL(u);
	}
	
	public String getChatIcon()
			throws PmpException
		{
			// get icon file name
			if (ICON_FILE_PATH == null) throw new PmpException("ICON_FILE_PATH not set in pst.properties file.");
			
			String chatIconURL = ICON_URL;
			String temp = getStringAttribute("PictureFile");	// 12345.gif
			if (temp == null) temp = ICON_DEFAULT;				// use default icon
			if (temp != null) chatIconURL += "/" + temp;		// complete URL path .../12345.gif
			
			return chatIconURL;
		}
	
	public String getSilence()
		throws PmpException
	{
		String opt = super.getOption(OPT_SILENCE);			// this returns 12345;12355; ...
		/*if (opt != null) {
			if (opt.equals(OPT_SILENCE) || opt.length()<=0)
				opt = null;		// no user set to silence
		}*/
		
		if (StringUtil.isNullOrEmptyString(opt))
			opt = "";
		return opt;											// returns "" or 12345;12355; ...
	}

}//End class chat
