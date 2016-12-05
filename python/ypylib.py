# usefull utilities

import os
import sys
from subprocess import call
from inspect import stack

# library config
FULL_COLOR  = 1

# global defaults
quiet   = 0
pretend = 0
verbose = 0
debug   = 0
color   = 0

def init():
    """ Library init """

    set_prompt()
    

def set_prompt():
    """ Set console display message color formats """

    global ERR,WARN,INFO,BUG,PRT,OK,NORM_C
    if color:
        COL_H   = '\x1b['
        NORM_C  = COL_H + '0m'
        OK_C    = COL_H + '32m'
        ERR_C   = COL_H + '31;01m'
        WARN_C  = COL_H + '35;01m'
        INFO_C  = COL_H + '0m'
        BUG_C   = COL_H + '34m'
        PRT_C   = COL_H + '33m'
    else:
        COL_H = NORM_C = ERR_C = WARN_C = INFO_C  = ''
        BUG_C = PRT_C  = OK_C = ''
    
    if FULL_COLOR: 
        P_END = ''
    else:
        P_END = NORM_C
    OK      = OK_C   + 'OK:    ' + P_END
    ERR     = ERR_C  + 'ERR:   ' + P_END
    WARN    = WARN_C + 'WARN:  ' + P_END
    INFO    = INFO_C + 'INFO:  ' + P_END
    BUG     = BUG_C  + 'DEBUG: ' + P_END
    PRT     = PRT_C  + 'PRT:   ' + P_END

def check_root():
    """ Check if current user is root """
    if pretend == 1 or os.getuid() == 0 and os.getgid() == 0: 
        return 0
    else: 
        return -1

def msg(*args):
    """ Send formatted message to user """

    #global quiet
    #global debug

    msg = ''
    if args:
        type = args[0]
    else:
        type = INFO
    msg = ''.join(args)
    if quiet: return
    if type == ERR:
        msg = msg + NORM_C + '\n'
        sys.stderr.write(msg)
        return
    elif type == WARN:
        msg = msg + NORM_C + '\n'
        sys.stderr.write(msg)
        return
    elif type == BUG:
        if not debug: return
        #msg = '[%s,%s]%s'%(debug,verbose,msg)
        if verbose > 0: 
            mod = '%s'%(stack(0)[2][3])
            if mod == '<module>': mod = '__MAIN__'
            msg = '%s %s'%(mod,msg)
            if verbose > 1:
                msg = '%s - %s'%(stack(0)[2][1],msg)
    print msg,NORM_C

def msg_err(*args)  : msg(ERR,*args)
def msg_warn(*args) : msg(WARN,*args)
def msg_bug(*args)  : msg(BUG,*args)
def msg_info(*args) : msg(INFO,*args)
def msg_ok(*args)   : msg(OK,*args)

def os_run(cmd):
    """ Run a system command. """

    if pretend == 1: 
        msg(PRT,cmd)
    else: 
        return call(cmd, shell=True)

def os_runr(cmd):
    if check_root():
        msg_err('Only root can run "',cmd,'"')
        return -1
    return os_run(cmd)

def os_xrun(cmd):
    if os_run(cmd): sys.exit(-1)

def os_xrunr(cmd):
    if check_root():
        msg_err('Only root can run "',cmd,'"')
        sys.exit(-1)
    os_xrun(cmd)


def send_email(address,log):
    # TODO debug it as attachment 0 byte!

    import smtplib
    from email.mime.text import MIMEText
    from email.Encoders import encode_base64
    from email.MIMEMultipart import MIMEMultipart

    SUB_HEAD = 'QA result'
    FROM = 'qa_sw'
    MESG = 'Test result'

    msg = ''
    with open('/etc/ssmtp/ssmtp.conf','rb') as f:
        while msg.find('AuthUser='):
            msg = f.readline()
        guser = msg.split('User=')[1].rstrip()
        while msg.find('AuthPass='):
            msg = f.readline()
        passwd = msg.split('Pass=')[1]

    f = open(log,'rb')
    attachment = MIMEText('test')
    attachment.set_payload(f.read())
    print '+++'
    print attachment
    print '+++++'
    encode_base64(attachment)
    f.close()
    attachment.add_header('Content-Disposition','attachment',\
            filename=os.path.basename(log))

    msg = MIMEMultipart()
    #MIMEText('QA result')
    msg['Subject'] = 'proba email'
    msg['From'] = 'invenshure_qa'
    msg['To'] = address
    msg.attach(MIMEText('QA log'))
    msg.attach(attachment)
    print msg

    s = smtplib.SMTP('smtp.gmail.com',587)
    s.ehlo()
    s.starttls()
    s.ehlo()
    s.login(guser,passwd)
    s.sendmail('QA',[address],msg.as_string())
    s.quit()


# ============= config utililties ==================

def set_cmd_options(fn):
    """ Set command line options based on cfg_def definition """

    global args,C_DESC_S,C_EPI_S

    CFG_GROUP_NAME      = 0
    CFG_GROUP_TYPE      = 1
    CFG_GROUP_ITEM      = 2

    CFG_ITEM_NAME       = 0
    CFG_ITEM_TYPE       = 1
    CFG_ITEM_SHORTKEY   = 2
    CFG_ITEM_LONGKEY    = 3
    CFG_ITEM_DEFAULT    = 4
    CFG_ITEM_HELP       = 5

    if BUG_SETOPT and 0:
        pp = pprint.PrettyPrinter(indent=2)
        pp.pprint(cfg_def)

    for i in cfg_def:
        if i[CFG_GROUP_NAME] == C_TOOL:
            for j in i[CFG_GROUP_ITEM]:
                if j[CFG_ITEM_NAME] == C_DESC:
                    C_DESC_S = j[CFG_ITEM_TYPE]
                if j[CFG_ITEM_NAME] == C_EPI:
                    C_EPI_S = j[CFG_ITEM_TYPE]
    par = argparse.ArgumentParser(description=C_DESC_S,epilog=C_EPI_S)
    for i in cfg_def:
        if i[CFG_GROUP_TYPE] == T_G:
            for j in i[CFG_GROUP_ITEM]:
                _keys = []
                _help = ''
                if j[CFG_ITEM_SHORTKEY] != NA: 
                    _keys.append('-%s'%(j[CFG_ITEM_SHORTKEY]))
                if j[CFG_ITEM_LONGKEY] != NA:
                    if i[CFG_GROUP_NAME] == C_GLOBAL:
                        _keys.append('--%s'%(j[CFG_ITEM_LONGKEY]))
                    else:
                        _keys.append('--%s_%s'%(i[CFG_GROUP_NAME],\
                            j[CFG_ITEM_LONGKEY]))
                if j[CFG_ITEM_TYPE] == T_T or j[CFG_ITEM_TYPE] == T_S:
                    _action = j[CFG_ITEM_TYPE]
                    if j[CFG_ITEM_HELP] != NA:
                        _help = j[CFG_ITEM_HELP]
                    par.add_argument(*_keys,action=_action,help=_help)
                elif j[CFG_ITEM_TYPE] == T_V:
                    par.add_argument(*_keys,action='version',\
                            version=C_V_S)
                else: 
                    if BUG_SETOPT: msg('no argparse flag',str(j))
        else:
            if BUG_SETOPT: 
                msg('unknown group:',str(i[CFG_GROUP_TYPE]),str(i))
    # read back set arguments
    args = par.parse_args()

# utilities
def set_cfgfile_options():
    """ Set options based on config file, command line args and defaults """
    
    if BUG_SETOPT and 0: msg_bug(str(cfg.sections()))
    for i in cfg.sections():
        for j in cfg.items(i):
            if i == C_GLOBAL:
                x = j[0]
            else:
                x = '%s_%s'%(i,j[0])
            if BUG_SETOPT and 0: msg_bug('{%s}%s;%s'%(hasattr(args,x),x,j))

            if hasattr(args,x) and getattr(args,x) != None: 
                continue
            setattr(args,x,j[1])

def get_cfgfile_options(fn):
    """ Read configuration file """

    cp_cfg = ConfigParser.RawConfigParser()
    cp_cfg.read(fn)
    if BUG_CFGRD:
        for i in cp_cfg.sections():
            msg_bug('section: ',i,': ','%s'%(cp_cfg.items(i)))
    return cp_cfg

