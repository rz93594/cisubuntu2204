#!/usr/bin/env bash
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_ntp_configured_authorized_timeserver.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       08/02/22    Recommendation "Ensure ntp is configured with authorized timeserver"
#

deb_ensure_ntp_configured_authorized_timeserver()
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

	if [ -z "$G_PQ" ] || [ -z "$G_PM" ]; then
		nix_package_manager_set
	fi

   deb_ensure_ntp_configured_authorized_timeserver_chk()
   {
      if ! $G_PQ ntp &>/dev/null; then
			test=NA
		else
			echo -e "- Start check - Ensure ntp is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
      	l_pool_count="" l_server_count="" l_test=""

         l_pool_count="$(grep -Po '^\h*pool\s+\S+' /etc/ntp.conf | wc -l)"
         l_server_count="$(grep -Po '^\h*server\s+\S+' /etc/ntp.conf | wc -l)"

         if [ $l_pool_count -ge 1 ]; then
            echo -e "- NTP configuration appears to be using pool mode\n- NTP pools in use:\n$(grep -P '^\h*pool\s+\S+' /etc/ntp.conf)" | tee -a "$LOG" 2>> "$ELOG"
            l_test=passed
         elif [ $l_server_count -ge 3 ]; then
            echo -e "- NTP configuration appears to be using server mode\n- NTP servers in use:\n$(grep -P '^\h*server\s+\S+' /etc/ntp.conf)" | tee -a "$LOG" 2>> "$ELOG"
            l_test=passed
         else
            echo -e "- No pool or server entries were found in /etc/ntp.conf " | tee -a "$LOG" 2>> "$ELOG"
         fi

         if [ "$l_test" = passed ]; then
				echo -e "- PASS:\n- NTP is configured to use a time server"  | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure ntp is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			else
				echo -e "- FAIL:\n- NTP is NOT configured to use a time server" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure ntp is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_FAIL:-102}"
			fi
      fi
   }

   deb_ensure_ntp_configured_authorized_timeserver_fix()
   {
      echo -e "- Start remediation - Ensure ntp is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"

      echo -e "- Edit /etc/ntp.conf and add or edit server or pool lines as appropriate according to local site policy." | tee -a "$LOG" 2>> "$ELOG"
      test=manual

      echo -e "- End remediation - Ensure ntp is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
   }

   deb_ensure_ntp_configured_authorized_timeserver_chk
   if [ "$?" = "101" ] || [ "$test" = "NA" ]; then
      [ -z "$test" ] && test="passed"
   else
      deb_ensure_ntp_configured_authorized_timeserver_fix
      if [ "$test" != "manual" ]; then
         deb_ensure_ntp_configured_authorized_timeserver_chk
      fi
   fi

	# Set return code and return
	case "$test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo "Recommendation \"$RNA\" Chrony is not installed on the system - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac

}