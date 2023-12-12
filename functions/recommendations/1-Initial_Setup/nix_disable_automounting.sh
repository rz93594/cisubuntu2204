#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_disable_automounting.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/11/20    Recommendation "Disable Automounting"
# Justin Brown		   07/31/22    Updated to modern format

disable_automounting()
{

	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""
	l_service="autofs"

   disable_automounting_chk()
   {
      echo -e "- Start check - Disable Automounting" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_service_test=""

		if [ -z "$(systemctl is-enabled $l_service | grep -i enabled)" ]; then
			if [ -z "$l_output" ]; then
            l_output="$l_service appears to be masked or not installed" && l_service_test=passed
         else
            l_output="$l_output\n$l_service appears to be masked or not installed\n$(systemctl is-enabled $l_service)"
         fi
		fi

      if [ "$l_service_test" = "passed" ]; then
			echo -e "- PASS:\n- $l_output"  | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Disable Automounting" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Disable Automounting" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
   }

   disable_automounting_fix()
   {
      echo -e "- Start remediation - Disable Automounting" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Stopping $l_service" | tee -a "$LOG" 2>> "$ELOG"
		systemctl stop $l_service
		echo -e "- Masking $l_service" | tee -a "$LOG" 2>> "$ELOG"
		systemctl mask $l_service

		if [ -z "$(systemctl is-enabled $l_service | grep -i enabled)" ]; then
			test=remediated
		fi

      echo -e "- End remediation - Disable Automounting" | tee -a "$LOG" 2>> "$ELOG"
   }

   disable_automounting_chk
   if [ "$?" = "101" ]; then
      [ -z "$test" ] && test="passed"
   else
      disable_automounting_fix
      if [ "$test" != "manual" ]; then
         disable_automounting_chk
      fi
   fi

   # Set return code, end recommendation entry in verbose log, and return
   case "$test" in
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