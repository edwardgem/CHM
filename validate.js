var numb = '0123456789';
var lwr = 'abcdefghijklmnopqrstuvwxyz';
var upr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function found(parm,val) {
  if (parm == "") return false;
  for (i=0; i<parm.length; i++) {
    if (val.indexOf(parm.charAt(i),0) != -1) return true;
  }
  return false;
}

function hasNum(parm) {return found(parm,numb);}
function hasAlpha(parm) {return found(parm,lwr+upr);}
