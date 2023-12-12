#!/usr/bin/env bash
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_ntp_running_as_user_ntp.sh
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/26/22    Recommendation "Ensure ntp is running as user ntp"
# 

deb_ensure_ntp_running_as_user_ntp()
{
	nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM -y remove"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM -y purge"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	
	deb_ensure_ntp_running_as_user_ntp_chk()
	{
		echo -e "- Start check - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_pkgmgr=""

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		if [ -z "$l_output" ]; then
			! $G_PQ ntp | grep -Pq "^Status:\s+install\s+ok\s+installed" > /dev/null 2>&1 && l_test="NA"

			if [ "$l_test" != "NA" ]; then
				l_output="$(ps -ef | awk '(/[n]tpd/ && $1!="ntp")')"

				if [ -z "$l_output" ]; then 
					echo -e "\n- PASS:\n- ntpd is running as ntp"
					echo -e "- End check - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-101}" 
				else 
					echo -e "\n- FAIL:\n$l_output\n"
					echo -e "- End check - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-102}" 
				fi
			fi
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}
	
	deb_ensure_ntp_running_as_user_ntp_fix()
	{
		echo -e "- Start remediation - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
        l_fafile=""
		l_searchloc="/etc/init.d/ntp /usr/lib/ntp/ntp-systemd-wrapper"

		# comment out incorrect user entries in config file(s)
		l_fafile="$(grep -Pl -- "^\s*RUNASUSER\s*=" $l_searchloc)"
		
		if [ -n "$l_fafile" ]; then
			echo -e "- Correct user entries in config file(s)" | tee -a "$LOG" 2>> "$ELOG"
			for l_file in $l_fafile; do 
				echo -e "- Updating \"RUNASUSER\" in \"$l_file\"" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/^\s*(RUNASUSER\s*=\s*\S+)(.*)?$/RUNASUSER=ntp\2/' $l_file
			done

			# restart ntp
			echo -e "- Restarting ntp" | tee -a "$LOG" 2>> "$ELOG"
			systemctl restart ntp
		fi
		
		echo -e "- End remediation - Ensure ntp is running as user ntp" | tee -a "$LOG" 2>> "$ELOG"
	
	}
	
	deb_ensure_ntp_running_as_user_ntp_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
    elif [ "$l_test" = "NA" ]; then
        l_test="NA"
	else
		deb_ensure_ntp_running_as_user_ntp_fix
		deb_ensure_ntp_running_as_user_ntp_chk
		if [ "$?" = "101" ] ; then
			[ "$l_test" != "failed" ] && l_test="remediated"
		else
			l_test="failed"
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