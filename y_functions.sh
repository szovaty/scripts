#!/bin/bash
# Linux generic function script by http://www.DDr.hu
Y_FUNC_VER="0.7"
Y_FUNC_LASTMOD="2017.05.15"

# terminal color settings
#USE_COLOR="yes" ; set this before sourcing this file!
if [ "$USE_COLOR" = "yes" ] ; then
    NORM=$'\e[0m'
    GOOD=$'\e[32m'
    ERR=$'\e[31;01m'
    BAD=$ERR
    WARN=$'\e[35;01m'
    ATTEN=$'\e[33;01m'
    LINK=$'\e[34;01m'
    BLINK=$'\e[5m'
    BLINKOFF=$'\e[25m'
    REV=$'\e[7m'
    REVOFF=$'\e[27m'
else
    NORM=""
    GOOD=""
    ERR=""
    BAD=""
    WARN=""
    ATTEN=""
    LINK=""
    BLINK=""
    BLINKOFF=""
    REV=""
    REVOFF=""
fi

# positioning
if [ "$USE_POS" = "yes" ] ; then
    COLS="`stty size 2>/dev/null`"
    COLS=$((${COLS#*' '}-8))
    ENDCOL=$'\e[A\e['$COLS'G'
else
    ENDCOL=""
fi

# Global definition
YES="yes"
NO="no"
TRUE="true"
FALSE="false"
ERROR=1
NOERROR=0
Y_DATE="date +%Y.%m.%d-%T"

# use these to set cleanup on exit
#MOUNTED=
#DELETE_ON_EXIT=
#LAST_CMD=

#Default definitions
test -z "$LOG" && LOG="/dev/null"
test -z "$TMP_DIR" && TMP_DIR="/tmp"
test -z "$WORK_DIR" && WORK_DIR="/tmp"
test -z "$CMD_WHICH" && CMD_WHICH="which"
test -z "$STD_ERR" && STD_ERR="/dev/stderr"
test -z "$STD_OUT" && STD_OUT="/dev/stdout"

# Generic funtion definitions

# bells
y_bell () {	
	test "$USE_BELL" = "yes" &&	{ 
		echo -en "\\007"
		case $1 in
			ERROR)	sleep 0.3; echo -en "\\007";;
			FATAL) sleep 0.3; echo -en "\\007"; sleep 0.3; echo -en "\\007";;
		esac
	}
}


# init_screen function
y_init_screen () {
    clear
    echo -e ${NORM}
    echo "======================================================================="
    echo -e "            ${GOOD}Welcome to $PROGRAM_NAME Ver. $VERSION"${NORM}
    echo -e "                     by ${LINK}http://www.DDr.hu"${NORM}
    echo "======================================================================="
    echo 
    echo
    echo "For help exit now and start the program with --help option."
    echo -e "      Like this:   ${GOOD}${0##*/} --help${NORM}"
    echo
    y_get_confirm "   Continue? ($YES):"
}

# self documenting program options from the source
# return opts as a string with commants for source
# add #; at the begin of a line that you want to show up on the help screen
y_help_opt () {
    local HELPMSG MSG DEF i j k x
    IFS=$'\n'
    for i in `cat $0 | grep -e '#;'` ; do
	HELPMSG="${i##*'#;'}"
	#i=${i#*[' ',$'\t']}
	i=${i%)*} ; 
	if [ "${i##*'#;'}" = "${HELPMSG}" ] ; then printf "%25s %s\n" ' ' $HELPMSG ; continue ; fi
	IFS=$'|'
	for j in $i ; do
	    if [ "${j%\$*}" = "$j" ] ; then k=$i ; break ; fi
	    eval x='$'${j#*\$}
	    if [ -z "$k" ] ; then k=$x ; else k="$k|$x" ; fi
	done
	k="${k}:"
	IFS=$' \t\n' ; MSG="" ; DEF=""
	for j in $HELPMSG ; do
	    if [ "${j#*[}" != "$j" ] ; then eval j='$'${j#*[} ; DEF="[${j}" ; continue ; fi
	    MSG="$MSG $j"
	done
	IFS=$'\n'
	k=`echo $k | awk ' { print $1 }'`
	printf "%25s %-40s %s\n" "${k}" "$MSG" "$DEF" 
	k=""
    done
    IFS=$' \t\n'
}

# generic message function
# usage: y_mesg type dest mess
#	type: fatal_error, error, warning, debug, info
#	dest: 0 - stdout/stderr ; 1 - log_file ; 2 - both
# 	mess: message to report
# return $ERROR | $NOERROR
y_error () 	 { y_msg "ERROR" "$1" "$2" ; }
y_fatal_error () { y_msg "FATAL" "$1" "$2" ; }
y_warning () 	 { y_msg "WARNING" "$1" "$2" ; }
y_debug ()	 { test -n "$Y_DEBUG" && y_msg "DEBUG" "$1" "$2" ; }
y_info ()	 { y_msg "INFO" "$1" "$2" ; }
y_usage ()	 { y_msg "USAGE" "$1" "$2" ; }
y_help ()	 { 
	y_msg "INFO" 0 "$PROGRAM_NAME Version $VERSION; $LAST_MOD"
	y_msg "HELP" 0 "${0##*/} `echo $1 ; shift ; y_help_opt ; echo $*`"
}
y_msg () {
    local DEST MESG MESG_COLOR CALL_EXIT RSTAT MSG_OUT BELL

    test -w "$LOG" || {
	test -e "$LOG" || touch "$LOG" 2>/dev/null
	test -w "$LOG" || LOG=/dev/null
    }
    MESG_HEADER="$1"
    case $1 in
			FATAL)	 MESG_COLOR=$ERR  ; CALL_EXIT=$YES ; MSG_OUT=$STD_ERR ; BELL=FATAL;;
			ERROR)	 MESG_COLOR=$ERR  ; CALL_EXIT=$NO  ; MSG_OUT=$STD_ERR ; BELL=ERROR;;
			WARNING) MESG_COLOR=$WARN ; CALL_EXIT=$NO  ; MSG_OUT=$STD_ERR ; BELL=WARNING;;	
			DEBUG)	 MESG_COLOR=$NORM ; CALL_EXIT=$NO  ; MSG_OUT=$STD_OUT ;;
			INFO)	 MESG_COLOR=$NORM ; CALL_EXIT=$NO  ; MSG_OUT=$STD_OUT ;;
			USAGE)	 MESG_COLOR=$WARN ; CALL_EXIT=$YES ; MSG_OUT=$STD_ERR ;;
			HELP)	 MESG_COLOR=$NORM ; CALL_EXIT=$NO ; MSG_OUT=$STD_OUT ;;
			*)       return $ERROR
    esac
	MSG_OUT=$STD_ERR
    test ! -w "$MSG_OUT" && MSG_OUT=/dev/null
#    test -n "$Y_QUIET" && MSG_OUT=/dev/null

    MESG_HEADER=`printf "%020s(%05d) %08s" ${0##*/} $$ $1`
    MESG_HEADER1=`printf "%08s" $1`
    DEST="$2" ; MESG="$3" 
    test -z "$3" && { DEST=2 && if [ -z "$2" ] ; then MESG="NO MESSAGE" ; else MESG=$2 ; fi ; }

    if [ "$DEST" = "0" -o "$DEST" = "2" ] ; then 
		echo -e "  ${MESG_COLOR}${MESG_HEADER1}: $MESG${NORM}" >> $MSG_OUT
    fi
    if [ "$DEST" = "1" -o "$DEST" = "2" ] ; then 
		echo -e "  `$Y_DATE` ${MESG_HEADER}: ${MESG}" >> $LOG 2>/dev/null
    fi
	test -n "$BELL" && y_bell $BELL
    test "$CALL_EXIT" = "$YES" && y_exit $ERROR
}

# clean up and exit
# set LAST_CMD, MOUNTED and DELETE_ON_EXIT lists
y_exit () {
	local i EXIT_STAT=0
	test -n "$1" && EXIT_STAT=$1
	if [ -n "$MOUNTED" ] ; then
		for i in $MOUNTED ; do
			`umount -l $i > /dev/null`
			test "$?" = "1" && y_error 2 "umount $i"
		done
	fi
	for i in "$DELETE_ON_EXIT" ; do
		`rm -f -r $i > /dev/null`
		test "$?" -ne 0 && y_error 2 "delete $i"
	done
	y_info 1 "  End: $0"
	test -n "$LAST_CMD" && { $LAST_CMD ; EXIT_STAT=$? ; }
	IFS=$' \t\n'
	exit $EXIT_STAT
}

y_start () { 
    y_info 1 "Start: $0 $1 ; [V${VERSION} , Last modified: ${LAST_MOD}]"
}
# print version information
y_version () { echo "Version: V$VERSION ; Last Mod. $LAST_MOD" ; }

# ask user if OK to continue
y_get_confirm () {
    local X
    test -z "$Y_CONFIRM" && return
    echo -n $*" " ; read X
    test "$X" != "$YES" && y_exit
}

# report progress
y_progress () { test -z "$Y_QUIET" && printf "%s%010s%s: %s\n" "${GOOD}" "PROGRESS" "${NORM}" "$1" >>/dev/stderr ; }
y_progress_1 () { printf "%s%010s%s: %s" "${GOOD}" "PROGRESS" "${NORM}" "$1" >>/dev/stderr ; }
y_progress_end () { 
	test -z "$Y_QUIET" || return
    case $1 in
			0)	echo -e "${ENDCOL}${LINK}[ ${GOOD}OK ${LINK}]${NORM}" >>/dev/stderr ;;
			1)	echo -e "${ENDCOL}${LINK}[ ${ERR}!! ${LINK}]${NORM}" >>/dev/stderr ;; 
			2)	echo -e "${ENDCOL}${LINK}[ ${WARN}-- ${LINK}]${NORM}" >>/dev/stderr ;; 
			*)	echo -e "${ENDCOL}${LINK}[ ${WARN}?? ${LINK}]${NORM}" >>/dev/stderr ;; 
    esac
}

# report disk size in MBytes
# usage: y_get_disksize disk
# return: disk size in MBytes
y_get_disksize () {
    local x
    x=`fdisk -l $1 2>/dev/null | grep ${1}: | awk ' { print $5 }'` 
y_debug 1 "DISK_SIZE=[$x]"
#    x=${x%' '*} ; x=${x##*' '} ; 
    x=$(($x/1024/1024))
    echo $x
}

# get_dir_size: get dir size of a list of dirs
#  usage: get_dir_size list_of_dirs
#  return: set sum dir size in DIR_SIZE
# local variables: *_4
y_get_dirsize () { 
    local x ; x=`du -s -c -m $1 | grep total` ; x=`echo $x`
    x=${x%%total} ; return $x
}

# get dir size minus the exclude dirs in the second parameter (a file with the list like tar exclude)
#  usage: getdirsize_excl dir_name filename_with_exclude_list_in extra_option_for_du
#  return: set dir size in DIR_SIZE variable
y_get_dirsize_excl () {
    local i ; local j ; local x ; local FROM
    
    FROM=$1 ; j=""
    for i in `ls -A $1 2>/dev/null | grep --file=$2 -v 2>/dev/null` ; do
	j="$j ${FROM%/}/$i"
    done 
    x=`$RCMD du -s $3 -c $j_5 2>/dev/null | grep total 2>/dev/null`
    x=`echo $x`
    return ${x%%total}
}

# get free space on device
y_get_free_space () {
    local x
    x=`df $1 | grep /` ; x=`echo ${x#*' '}` ; x=`echo ${x#*' '}` ; x=`echo ${x#*' '}`
    x=`echo ${x%%$Y*}`; return $x
}

# check if commands are available
# usage: y_check_cmds command_list
y_check_cmds () {
    local i CMD
    for i in $1 ; do
	CMD=`which $i 2>&1`
	test "$?" = "1" && { y_error 2 "Command $i not found!" ; return $ERROR ; }
	test -x "$CMD" || { y_error 2 "Can not run $CMD command" ; return $ERROR ; }
    done
}


# check if a program return with no error
# if error then call y_fatal_error
y_check_exec () { test "$1" -ne 0 && y_fatal_error 2 "Failed command: $2" ; }

y_run_cmd () {
    local OUT error
    test -z "$1" && return
    y_debug 1 "call: $1"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && { $1 >>$OUT  2>>$LOG ; y_check_exec $? "$1" ; }
    return 0
}


y_run_cmd1 () { 
    test -z "$1" && return
    y_debug 1 "call: $1"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && { $1 >>$OUT 2>>$LOG ; return "$?" ; }
    return 0
}

y_run_cmd2 () { 
    local RET
    test -z "$1" && return
    y_debug 1 "call: $1"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && { 
			$1 >>$OUT 2>>$LOG ; RET=$?
			test "$RET" -ne 0 && y_error 1 "Failed command: $1"
			return $RET
    }
    return 0
}


y_run () {
    local OUT
    test -z "$1" && return
    y_debug 1 "call: $*"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && 
        { eval $* >>$OUT  2>>$LOG ; y_check_exec $? "$*" ; }
    return 0
}

y_run1 () { 
    test -z "$1" && return
    y_debug 1 "call: $*"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && { eval $* >>$OUT 2>>$LOG ; return "$?" ; }
    return 0
}

y_run2 () { 
    local RET
    test -z "$1" && return
    y_debug 1 "call: $*"
    if [ -n "$Y_DEBUG" ] ; then OUT=${LOG} ; else OUT=/dev/null ; fi
    test -z "${Y_DRY_RUN}" && { 
	eval $* >>$OUT 2>>$LOG ; RET=$?
	test "$RET" -ne 0 && y_error 1 "Failed command: $*"
	return $RET
    }
}

y_set_default () { local X ; eval X='$'$1 ; test -z "$X" && eval $1=\"$2\" ; }
y_mark_log () {	echo "========================================================================"; }
