#!/usr/bin/env sh
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_authentication_required_single_user_mode.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/18/20    Recommendation "Ensure authentication required for single user mode"
# Justin Brown       08/23/22    Updated to modern format
#

deb_ensure_authentication_required_single_user_mode()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""

   deb_ensure_authentication_required_single_user_mode_chk()
	{
      	echo -e "- Start check - Ensure authentication required for single user mode" | tee -a "$LOG" 2>> "$ELOG"
      	l_output=""
      
		l_output="$(grep -Eq '^root:\$[0-9]' /etc/shadow || echo \"root is locked\")"
		
		if [ -z "$l_output" ]; then
			echo -e "- PASS: - Root has a password set"  | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure authentication required for single user mode" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL: - \n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure authentication required for single user mode" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}

   deb_ensure_authentication_required_single_user_mode_fix()
	{
		echo -e "- Start remediation - Ensure authentication required for single user mode" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Run the following command and follow the prompts to set a password for the root user:\n\"# passwd root\"\n- Making modifications to the root account could have significant unintended consequences or result in outages and unhappy users, exercise caution when setting a new root password." | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- End remediation - Ensure authentication required for single user mode" | tee -a "$LOG" 2>> "$ELOG"
		l_test="manual"
	}

   deb_ensure_authentication_required_single_user_mode_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		deb_ensure_authentication_required_single_user_mode_fix
		if [ "$l_test" != "manual" ]; then
			deb_ensure_authentication_required_single_user_mode_chk
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