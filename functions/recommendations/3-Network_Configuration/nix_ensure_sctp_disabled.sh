#!/usr/bin/env bash
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_sctp_disabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/19/22    Recommendation "Ensure SCTP is disabled"
# 

ensure_sctp_disabled()
{

	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
			
	ensure_sctp_disabled_chk()
	{
		l_output="" l_output2=""

		# set module name 
		l_mname="sctp"

		echo "- Start check - Ensure SCTP is disabled" | tee -a "$LOG" 2>> "$ELOG" 
		
		# Check how module will be loaded
		l_loadable="$(modprobe -n -v "$l_mname")" 
		
		if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then 
			l_output="$l_output\n - module: \"$l_mname\" is not loadable: \"$l_loadable\"" 
		else 
			l_output2="$l_output2\n - module: \"$l_mname\" is loadable: \"$l_loadable\"" 
		fi
		
		# Check is the module currently loaded
		if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
			l_output="$l_output\n - module: \"$l_mname\" is not loaded" 
		else 
			l_output2="$l_output2\n - module: \"$l_mname\" is loaded" 
		fi 
		
		# Check if the module is deny listed 
		if grep -Pq -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*; then
			l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pl -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*)\"" 
		else 
			l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed" 
		fi 
		
		# Report results. If no failures output in l_output2, we pass 
		if [ -z "$l_output2" ]; then 
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure SCTP is disabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_PASS:-101}" 
		else 
			echo -e "- FAIL:\n- Reason(s) for audit failure:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure SCTP is disabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_FAIL:-102}" 
		fi
	}


	ensure_sctp_disabled_fix()
	{
		echo "- Start remediation - Ensure SCTP is disabled" | tee -a "$LOG" 2>> "$ELOG"
		
		if ! modprobe -n -v "$l_mname" | grep -P -- '^\h*install \/bin\/(true|false)'; then
		 	echo -e " - Setting module: \"$l_mname\" to be not loadable" 
			echo -e "install $l_mname /bin/false" >> /etc/modprobe.d/"$l_mname".conf 
		fi 
		
		if lsmod | grep "$l_mname" > /dev/null 2>&1; then 
			echo -e " - Unloading module \"$l_mname\""
			modprobe -r "$l_mname"
		fi 
		
		if ! grep -Pq -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*; then 
			echo -e " - Deny listing \"$l_mname\"" 
			echo -e "blacklist $l_mname" >> /etc/modprobe.d/"$l_mname".conf 
		fi

		echo "- End remediation - Ensure SCTP is disabled" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	ensure_sctp_disabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_sctp_disabled_fix
		if [ "$l_test" != "manual" ]; then
			ensure_sctp_disabled_chk
			if [ "$?" = "101" ]; then
				[ "$l_test" != "failed" ] && l_test="remediated"
			else
				l_test="failed"
			fi
		fi
	fi

	# Set return code, end recommendation entry in verbose log, and return
	case "$l_test" in
		passed)
			echo -e "- Result - No remediation required\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo -e "- Result - successfully remediated\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo -e "- Result - requires manual remediation\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo -e "- Result - Recommendation is non applicable\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo -e "- Result - remediation failed\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac	
	
}