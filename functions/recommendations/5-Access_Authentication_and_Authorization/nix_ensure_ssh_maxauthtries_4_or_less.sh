#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_ssh_maxauthtries_4_or_less.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/22/20    Recommendation "Ensure SSH MaxAuthTries is set to 4 or less"
# Justin Brown       05/14/22    Updated to modern format
# 
 
ensure_ssh_maxauthtries_4_or_less()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""
   
   nix_package_manager_set()
	{
		echo "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"
		if command -v rpm 2>/dev/null; then
			echo "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM -y remove"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM -y purge"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}   
   
   ensure_ssh_maxauthtries_4_or_less_chk()
	{
      echo -e "- Start check - Ensure SSH MaxAuthTries is set to 4 or less" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_sshd_cmd="" l_sshd_config=""
      
      if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
         nix_package_manager_set
      fi
      
      # Check is openssh-server is installed
      if ! $G_PQ openssh-server >/dev/null ; then
         test=NA
      else
         if sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Eq 'maxauthtries\s+[1-4]'; then
            l_output="- Entry found in sshd -T -C output: $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -E 'maxauthtries\s+[1-4]')" && l_sshd_cmd="passed"
         else
            l_output="- No entry found in sshd -T -C output" && l_sshd_cmd="failed"
         fi
         
         if grep -Piq '^\s*maxauthtries\s+([5-9]|[1-9][0-9]+)' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Incorrect entry found in sshd_config: $(grep -Pi '^\s*maxauthtries\s+([5-9]|[1-9][0-9]+)' /etc/ssh/sshd_config)" && l_sshd_config="failed"
         elif grep -Piq '^\s*#\s*maxauthtries\s+' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Incorrect entry found in sshd_config: $(grep -Pi '^\s*#\s*maxauthtries\s+' /etc/ssh/sshd_config)" && l_sshd_config="failed"
         elif grep -Piq 'maxauthtries\s+[1-4]' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Entry found in sshd_config: $(grep -Pi '^\s*maxauthtries\s+[1-4]' /etc/ssh/sshd_config)" && l_sshd_config="passed"
         else
            l_output="$l_output\n- NO Entry found in sshd_config for MaxAuthTries" && l_sshd_config="failed"
         fi
      fi
      
      if [ "$l_sshd_cmd" = "passed" ] && [ "$l_sshd_config" = "passed" ]; then
         echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure SSH MaxAuthTries is set to 4 or less" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_PASS:-101}"
      else
         echo -e "- FAIL:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure SSH MaxAuthTries is set to 4 or less" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_FAIL:-102}"
      fi
   }
   
   ensure_ssh_maxauthtries_4_or_less_fix()
	{
      echo -e "- Start remediation - Ensure SSH MaxAuthTries is set to 4 or less" | tee -a "$LOG" 2>> "$ELOG"
      
      if grep -Piq '^\h*(#\s*)?maxauthtries\s' /etc/ssh/sshd_config; then
         echo -e "- Updating MaxAuthTries entry in /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
         sed -ri 's/^\s*(#\s*)?([Mm]ax[Aa]uth[Tt]ries)(\s+\S+\s*)(\s+#.*)?$/\2 4\4/' /etc/ssh/sshd_config
      else
         echo -e "- Adding LogLevel entry to /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
         sed -E -i '/^\s*\#\s*Authentication/a MaxAuthTries 4' /etc/ssh/sshd_config
      fi
      
      echo -e "- End remediation - Ensure SSH MaxAuthTries is set to 4 or less" | tee -a "$LOG" 2>> "$ELOG"
   }
   
   ensure_ssh_maxauthtries_4_or_less_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
      if [ "$test" != "NA" ]; then
         ensure_ssh_maxauthtries_4_or_less_fix
         ensure_ssh_maxauthtries_4_or_less_chk
		 if [ "$?" = "101" ]; then
            [ "$test" != "failed" ] && test="remediated"
         else
            test="failed"
         fi
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