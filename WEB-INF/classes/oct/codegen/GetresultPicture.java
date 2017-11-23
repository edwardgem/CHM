
//
//	Copyright (c) 2005, EGI Technologies, Inc..  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	GetPicture.java
//	Author:	Marcus Hui
//	Date:	10/2/2001
//  Description:
//      Servlet to obtain an image given an id.
//
//  Required:
//      user    - name of attribute holding the user session in the web session
//      objId   - the object id
//      img     - default image if product does not have an existing image
//		att		- the attribute name that the picture stores in
//
//	Modification:
/////////////////////////////////////////////////////////////////////

package oct.codegen;
import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.pmp.exception.PmpAttributeNotFoundException;
import oct.pst.PstUserAbstractObject;

public class GetresultPicture extends HttpServlet
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
        String img = null;
        try
        {

            String pUserVar = request.getParameter("user");
            String pObjName = request.getParameter("objName");
            String attName = request.getParameter("att");

    	    String objName = pObjName;
            img = request.getParameter("img");
            HttpSession webSession = request.getSession(false);

            if (webSession==null || pUserVar==null)
                throw new Exception(""); //display default image

            PstUserAbstractObject user = (PstUserAbstractObject)webSession.getAttribute(pUserVar);

            if (user==null)
                throw new Exception(""); //display default image

			resultManager objMgr = resultManager.getInstance();
	  		result obj = (result)objMgr.get(user, objName);

            byte[] b = (byte [])obj.getAttribute(attName)[0];

            if (b==null || b.length <1)
               throw new PmpAttributeNotFoundException();

            response.setContentType("image");
            OutputStream os = response.getOutputStream();
            os.write(b);
            os.flush();
            return;
        }
        catch (Exception e)
        {
		    System.out.println("GetPhoto error: " + e.toString());
            // no image found, send default image if given
            if (img!=null && img.length()>0)
            {
                // Cannot get image, send default image
                RequestDispatcher d = request.getRequestDispatcher(img);
                if (d==null)
                {
                    throw new ServletException("Cannot find image " + img);
                }
                d.forward(request, response);
            }
            else
            {
                e.printStackTrace();
                throw new ServletException(e.toString());
            }
        }

    }
}
