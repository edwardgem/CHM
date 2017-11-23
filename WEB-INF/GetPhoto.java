//
//	Copyright (c) 2000 Objectsoft Corporation.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Oliver Chung
//	Date:	$Date$
//  Description:
//      Servlet to obtain an employee image given an id.
//
//  Required:
//      user    - name of attribute holding the user session in the web session
//      userId  - user id
//      img     - default image if product does not have an existing image
//
//	Modification:
/////////////////////////////////////////////////////////////////////

import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.userManager;
import oct.pmp.exception.PmpAttributeNotFoundException;
import oct.pst.PstUserAbstractObject;
/**
* Servlet to retrieve image from PmpProduct and write to the client.
* Many things are hardcode to make it work, need a lot of clean up.
* @author Oliver Chung
* @version $Revision$
*/
public class GetPhoto extends HttpServlet
{
   /**
   * Handle GET requests
   */
   public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
   {
      getImage(request, response);
   }

   /**
   * Handle POST requests
   */
   public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
   {
      getImage(request, response);
   }

   public void getImage(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
   {
        String img =null;
        try
        {

            String pUserVar = request.getParameter("user");
            String pUserId = request.getParameter("userId");

    	    int uid = Integer.parseInt(pUserId);
            img = request.getParameter("img");
            HttpSession webSession = request.getSession(false);

            if (webSession==null || pUserVar==null)
            {
                throw new Exception(""); //display default image
            } // endif


            PstUserAbstractObject user = (PstUserAbstractObject)webSession.getAttribute(pUserVar);
            if (user==null)
            {
                throw new Exception(""); //display default image
            } // endif

			userManager userMgr = userManager.getInstance();
	  		PstUserAbstractObject employee = (PstUserAbstractObject)userMgr.get(user, uid);

	  		// ECC: Picture attribute is obsoleted, now we use PictureFile and should return a URL
            byte[] b = (byte [])employee.getAttribute("Picture")[0];
            if (b==null || b.length <1)
            {
               throw new PmpAttributeNotFoundException();
            } // endif

            response.setContentType("image");
            OutputStream os = response.getOutputStream();
            os.write(b);
            os.flush();
            return;
        }
        catch (Exception e)
        {
		    //System.out.println("GetPhoto error: " + e.toString());
            // no image found, send default image if given
            if (img!=null && img.length()>0)
            {
                // Cannot get image, send default image
                RequestDispatcher d = request.getRequestDispatcher(img);
                if (d==null)
                {
                    throw new ServletException("Cannot find image " + img);
                } // endif
                d.forward(request, response);
            }
            else
            {
                e.printStackTrace();
                throw new ServletException(e.toString());
            } // endif
        } // endcatch

    }//End getImage
}
