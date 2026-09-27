#!/usr/bin/env bash
# =============================================================================
#  sjekk-oblig.sh  -  selvtest for obligatorisk øving 1
# -----------------------------------------------------------------------------
#  Kontrollerer kravene K1-K12 mot repoet ditt, og mot Azure hvis du oppgir
#  argumentene. Skriptet LESER bare - det endrer ingenting, verken i repoet
#  eller i Azure.
#
#  Kjør det fra rota av repoet ditt:
#
#      ./sjekk-oblig.sh
#      ./sjekk-oblig.sh --app-id <app-id> --storage-account <konto> --container tfstate
#
#  Uten argumenter kjøres bare repo-kontrollene. Med argumentene kjøres også
#  Azure-kontrollene (K6 og K10).
#
#  Er du på Windows uten bash: kjør skriptet i Git Bash, WSL eller Azure Cloud
#  Shell. Cloud Shell har allerede bash, git og az.
#
#  Merk: skriptet kan ta feil. Mener du en AVVIK er urimelig, skriv det i
#  innleveringen og forklar hvorfor - det teller ikke mot deg å være uenig med
#  et skript, så lenge du begrunner det.
# =============================================================================

set -uo pipefail

APP_ID=""
STORAGE_ACCOUNT=""
CONTAINER="tfstate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-id)          APP_ID="${2:-}"; shift 2 ;;
    --storage-account) STORAGE_ACCOUNT="${2:-}"; shift 2 ;;
    --container)       CONTAINER="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "Ukjent argument: $1"
      echo "Bruk: $0 [--app-id <id>] [--storage-account <konto>] [--container <navn>]"
      exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
#  Utskrift
# ---------------------------------------------------------------------------

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  GRONN="$(tput setaf 2)"; ROD="$(tput setaf 1)"; GUL="$(tput setaf 3)"
  GRA="$(tput setaf 8 2>/dev/null || tput setaf 7)"; FET="$(tput bold)"; SLUTT="$(tput sgr0)"
else
  GRONN=""; ROD=""; GUL=""; GRA=""; FET=""; SLUTT=""
fi

ANTALL_OK=0
ANTALL_AVVIK=0
ANTALL_MANUELL=0
ANTALL_HOPPET=0
AVVIKSLISTE=()

ok()      { printf '  %sOK%s       %-5s %s\n' "$GRONN" "$SLUTT" "$1" "$2"; ANTALL_OK=$((ANTALL_OK+1)); }
avvik()   { printf '  %sAVVIK%s    %-5s %s\n' "$ROD" "$SLUTT" "$1" "$2"
            printf '           %s→ %s%s\n' "$GRA" "$3" "$SLUTT"
            ANTALL_AVVIK=$((ANTALL_AVVIK+1)); AVVIKSLISTE+=("$1"); }
manuell() { printf '  %sMANUELL%s  %-5s %s\n' "$GUL" "$SLUTT" "$1" "$2"
            printf '           %s→ %s%s\n' "$GRA" "$3" "$SLUTT"
            ANTALL_MANUELL=$((ANTALL_MANUELL+1)); }
hoppet()  { printf '  %sHOPPET%s   %-5s %s\n' "$GRA" "$SLUTT" "$1" "$2"
            printf '           %s→ %s%s\n' "$GRA" "$3" "$SLUTT"
            ANTALL_HOPPET=$((ANTALL_HOPPET+1)); }
bolk()    { printf '\n%s%s%s\n' "$FET" "$1" "$SLUTT"; }

# ---------------------------------------------------------------------------
#  Hjelpere
# ---------------------------------------------------------------------------

# Alle .tf-filer i repoet, uten .terraform/ og uten leverandørkode.
tf_filer() {
  find . -name '*.tf' -not -path './.terraform/*' -not -path '*/.terraform/*' \
       -not -path './.git/*' 2>/dev/null
}

# Teller treff uten å bruke `| grep -q`, som gir SIGPIPE under pipefail.
antall_treff() {
  local monster="$1"; shift
  grep -rIl --exclude-dir=.git --exclude-dir=.terraform -E "$monster" "$@" 2>/dev/null | wc -l | tr -d ' '
}

echo
printf '%sSelvtest for obligatorisk øving 1%s\n' "$FET" "$SLUTT"
printf '%sRepo: %s%s\n' "$GRA" "$(pwd)" "$SLUTT"

if [[ ! -d .git ]]; then
  printf '\n  %sDette ser ikke ut som rota av et git-repo.%s\n' "$ROD" "$SLUTT"
  printf '  Kjør skriptet fra mappa der .git ligger.\n\n'
  exit 1
fi

# ===========================================================================
#  A · KODEN
# ===========================================================================

bolk "A · Koden"

# --- K1: modul med de tre filene, og description på alle variabler ---------

MODULMAPPER=()
if [[ -d modules ]]; then
  while IFS= read -r d; do MODULMAPPER+=("$d"); done \
    < <(find modules -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi

if [[ ${#MODULMAPPER[@]} -eq 0 ]]; then
  avvik "K1" "Modul med main/variables/outputs" \
        "Fant ingen mappe under modules/. Kravet forutsetter modules/<navn>/"
else
  K1_FEIL=""
  for m in "${MODULMAPPER[@]}"; do
    for f in main.tf variables.tf outputs.tf; do
      [[ -f "$m/$f" ]] || K1_FEIL="${K1_FEIL}${m}/${f} mangler. "
    done
    # Variabler uten description
    if [[ -f "$m/variables.tf" ]]; then
      UTEN_DESC="$(awk '
        /^[[:space:]]*variable[[:space:]]+"/ {
          navn=$0; sub(/^[[:space:]]*variable[[:space:]]+"/,"",navn); sub(/".*/,"",navn)
          inblokk=1; harDesc=0; next
        }
        inblokk && /^[[:space:]]*description[[:space:]]*=/ { harDesc=1 }
        inblokk && /^[[:space:]]*}[[:space:]]*$/ {
          if (!harDesc) print navn
          inblokk=0
        }
      ' "$m/variables.tf" | tr '\n' ' ')"
      [[ -n "$UTEN_DESC" ]] && K1_FEIL="${K1_FEIL}Uten description i ${m}: ${UTEN_DESC}"
    fi
  done
  if [[ -n "$K1_FEIL" ]]; then
    avvik "K1" "Modul med main/variables/outputs" "$K1_FEIL"
  else
    ok "K1" "Modul med main/variables/outputs, alle variabler har description"
  fi
fi

# Brukes modulen av en stack?
if [[ -d stacks ]]; then
  BRUK="$(antall_treff 'module[[:space:]]+"' stacks)"
  if [[ "$BRUK" -eq 0 ]]; then
    avvik "K1" "Modulen brukes av en stack" \
          "Fant ingen module-blokk under stacks/. En ubrukt modul teller ikke"
  else
    ok "K1" "Modulen brukes av en stack"
  fi
else
  avvik "K1" "Modulen brukes av en stack" "Fant ingen stacks/-mappe"
fi

# --- K2: for_each i modulen ------------------------------------------------

if [[ ${#MODULMAPPER[@]} -gt 0 ]]; then
  FOREACH="$(antall_treff 'for_each[[:space:]]*=' modules)"
  COUNT="$(antall_treff '^[[:space:]]*count[[:space:]]*=' modules)"
  if [[ "$FOREACH" -gt 0 ]]; then
    ok "K2" "Flere like ressurser fra én blokk med for_each"
  elif [[ "$COUNT" -gt 0 ]]; then
    avvik "K2" "for_each i modulen" \
          "Fant count, men ikke for_each. Kravet ber om for_each - se modul 3"
  else
    avvik "K2" "for_each i modulen" \
          "Fant verken for_each eller count under modules/"
  fi
fi

# --- K3: locals, og ingen hardkodet subscription-ID ------------------------

if [[ -d stacks ]]; then
  LOCALS="$(antall_treff 'locals[[:space:]]*\{' stacks)"
  if [[ "$LOCALS" -gt 0 ]]; then
    ok "K3" "Navn bygges i locals"
  else
    avvik "K3" "Navn bygges i locals" \
          "Fant ingen locals-blokk under stacks/. Se modul 1, side 13-14"
  fi
fi

SUBS_TREFF="$(tf_filer | xargs grep -l '/subscriptions/' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$SUBS_TREFF" -eq 0 ]]; then
  ok "K3" "Ingen hardkodet /subscriptions/-ID i koden"
else
  avvik "K3" "Ingen hardkodet /subscriptions/-ID i koden" \
        "Fant /subscriptions/ i $SUBS_TREFF fil(er). Bruk data-kilder eller variabler"
fi

# --- K4: miljønavn ikke i fil- eller mappenavn under stacks/ ---------------

if [[ -d stacks ]]; then
  # Portabelt med vilje: `find -iregex` med \| er en GNU-utvidelse som BSD-find
  # på macOS ikke støtter - den feiler stille og slipper alt gjennom.
  #
  # Vi deler hvert stinavn på - _ og . og krever EKSAKT treff på et ledd, slik
  # at "stacks/dev" og "main-prod.tf" fanges, mens "producer.tf" og "latest.tf"
  # ikke gjør det.
  MILJONAVN=""
  while IFS= read -r sti; do
    [[ -z "$sti" ]] && continue
    LEDD="$(basename "$sti")"
    LEDD="${LEDD%.tf}"
    LEDD="$(printf '%s' "$LEDD" | tr '[:upper:]' '[:lower:]' | tr '\-_.' '   ')"
    for ord in $LEDD; do
      case "$ord" in
        dev|test|prod) MILJONAVN="${MILJONAVN}${sti} "; break ;;
      esac
    done
  done < <(find stacks -mindepth 1 -not -path '*/.terraform/*' 2>/dev/null)
  MILJONAVN="$(printf '%s' "$MILJONAVN" | cut -c1-160)"

  if [[ -z "$MILJONAVN" ]]; then
    ok "K4" "Én stack-definisjon - miljønavn ikke i fil- eller mappenavn"
  else
    avvik "K4" "Én stack-definisjon" \
          "Miljønavn i sti: ${MILJONAVN}- se modul 3, «én stack, mange instanser»"
  fi
fi

# ===========================================================================
#  B · STATE OG KONFIGURASJON
# ===========================================================================

bolk "B · State og konfigurasjon"

# --- K5: tom backend-blokk -------------------------------------------------

BACKEND_FILER="$(tf_filer | xargs grep -l 'backend[[:space:]]*"azurerm"' 2>/dev/null)"
if [[ -z "$BACKEND_FILER" ]]; then
  avvik "K5" "Tom backend \"azurerm\"-blokk" \
        "Fant ingen backend \"azurerm\"-blokk. Uten den havner state lokalt"
else
  K5_INNHOLD=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    REST="$(awk '
      /backend[[:space:]]*"azurerm"[[:space:]]*\{/ {
        rest=$0
        sub(/.*backend[[:space:]]*"azurerm"[[:space:]]*\{/, "", rest)
        if (rest ~ /\}/) { sub(/\}.*/, "", rest); print rest; exit }
        inblokk=1; next
      }
      inblokk && /^[[:space:]]*\}/ { exit }
      inblokk { print }
    ' "$f" | sed 's/#.*//' | sed 's,//.*,,' | tr -d '[:space:]')"
    [[ -n "$REST" ]] && K5_INNHOLD="${K5_INNHOLD}${f} "
  done <<< "$BACKEND_FILER"

  if [[ -z "$K5_INNHOLD" ]]; then
    ok "K5" "backend \"azurerm\"-blokka er tom"
  else
    avvik "K5" "backend \"azurerm\"-blokka er tom" \
          "Fant verdier i blokka i: ${K5_INNHOLD}- de hører i -backend-config"
  fi
fi

# --- K6: én key per miljø (krever Azure) -----------------------------------

if [[ -n "$STORAGE_ACCOUNT" ]]; then
  BLOBER="$(az storage blob list \
              --account-name "$STORAGE_ACCOUNT" \
              --container-name "$CONTAINER" \
              --auth-mode login \
              --query "[].name" -o tsv 2>/dev/null)"
  ANTALL_BLOBER="$(printf '%s\n' "$BLOBER" | grep -c 'tfstate' || true)"
  if [[ "$ANTALL_BLOBER" -ge 2 ]]; then
    ok "K6" "Fant $ANTALL_BLOBER state-filer i $CONTAINER"
  elif [[ "$ANTALL_BLOBER" -eq 1 ]]; then
    avvik "K6" "Én key per miljø" \
          "Fant bare én state-fil. To miljøer skal gi to blober"
  else
    avvik "K6" "Én key per miljø" \
          "Fant ingen state-filer i $CONTAINER på $STORAGE_ACCOUNT. Sjekk navn og tilgang"
  fi
else
  hoppet "K6" "Én key per miljø" \
         "Kjør på nytt med --storage-account <konto> --container <navn>"
fi

# --- K7: ingen .tfvars, heller ikke i historikken --------------------------

TFVARS_HIST="$(git log --all --diff-filter=A --name-only --pretty=format: -- '*.tfvars' 2>/dev/null \
               | grep -v '^$' | sort -u | tr '\n' ' ')"
TFVARS_NAA="$(find . -name '*.tfvars' -not -path './.git/*' -not -path '*/.terraform/*' 2>/dev/null | tr '\n' ' ')"

if [[ -z "$TFVARS_HIST" && -z "$TFVARS_NAA" ]]; then
  ok "K7" "Ingen .tfvars i repoet eller i historikken"
else
  MELDING=""
  [[ -n "$TFVARS_NAA" ]]  && MELDING="I arbeidsmappa: ${TFVARS_NAA}"
  [[ -n "$TFVARS_HIST" ]] && MELDING="${MELDING}I historikken: ${TFVARS_HIST}"
  avvik "K7" "Ingen .tfvars i repoet eller i historikken" \
        "${MELDING}- å slette fila i en ny commit fjerner den ikke fra historikken"
fi

# --- K8: ingen hemmeligheter -----------------------------------------------

K8_FUNN=""

# Tydelige mønstre i arbeidsmappa.
#
# Selvtestene utelates fra søket. Grunnen står på linja under: det FØRSTE
# mønsteret er en ren litteral, og skriptet du leser nå inneholder den - så
# uten denne ekskluderingen finner kontrollen seg selv og melder AVVIK på et
# repo som er helt rent. Kontrollen leser arbeidsmappa, ikke Git, så det
# hjelper ikke å la være å committe skriptet.
#
# Begge filnavnene utelates, ikke bare dette ene: studenten laster gjerne ned
# begge utgavene fra selvtest-sida og legger dem i samme mappe.
#
# De tre andre mønstrene er regexer og treffer ikke sin egen kildetekst -
# etter `client_secret` står det en `[`, ikke et likhetstegn.
for monster in 'AZURE_CREDENTIALS' 'client_secret[[:space:]]*=' 'access_key[[:space:]]*=' \
               'BEGIN [A-Z ]*PRIVATE KEY'; do
  TREFF="$(grep -rIl --exclude-dir=.git --exclude-dir=.terraform \
                --exclude='sjekk-oblig.sh' --exclude='Sjekk-Oblig.ps1' \
                -E "$monster" . 2>/dev/null | tr '\n' ' ')"
  [[ -n "$TREFF" ]] && K8_FUNN="${K8_FUNN}[${monster}] i ${TREFF}"
done

# Passord satt til en litteral streng som ikke er tom og ikke er en referanse.
PW_TREFF="$(tf_filer | xargs grep -lE '(password|secret)[a-z_]*[[:space:]]*=[[:space:]]*"[^"]+"' 2>/dev/null | tr '\n' ' ')"
[[ -n "$PW_TREFF" ]] && K8_FUNN="${K8_FUNN}[passord som litteral] i ${PW_TREFF}"

# State committet?
STATE_HIST="$(git log --all --diff-filter=A --name-only --pretty=format: -- '*.tfstate' 2>/dev/null \
              | grep -v '^$' | sort -u | tr '\n' ' ')"
[[ -n "$STATE_HIST" ]] && K8_FUNN="${K8_FUNN}[state i historikken] ${STATE_HIST}"

if [[ -z "$K8_FUNN" ]]; then
  ok "K8" "Ingen hemmelighet funnet i repoet"
else
  avvik "K8" "Ingen hemmelighet i repoet" "$K8_FUNN"
fi

# ===========================================================================
#  C · KOBLING
# ===========================================================================

bolk "C · Kobling"

REMOTE="$(antall_treff 'terraform_remote_state' . )"
if [[ "$REMOTE" -gt 0 ]]; then
  ok "K9" "Den andre stacken bruker terraform_remote_state"
else
  avvik "K9" "terraform_remote_state" \
        "Fant ingen bruk av terraform_remote_state. Se modul 4, side 7-9"
fi

# ===========================================================================
#  D · PIPELINE
# ===========================================================================

bolk "D · Pipeline"

# --- Finnes det en workflow i det hele tatt? -------------------------------

WF_MAPPE=".github/workflows"
if [[ -d "$WF_MAPPE" ]]; then
  ANTALL_WF="$(find "$WF_MAPPE" -name '*.yml' -o -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')"
else
  ANTALL_WF=0
fi

if [[ "$ANTALL_WF" -eq 0 ]]; then
  avvik "K11" "Workflow finnes" "Fant ingen filer i ${WF_MAPPE}/"
else
  # Den gamle passordvarianten av azure/login?
  GAMMEL="$(antall_treff 'creds:[[:space:]]*\$\{\{[[:space:]]*secrets' "$WF_MAPPE")"
  OIDC="$(antall_treff 'id-token:[[:space:]]*write' "$WF_MAPPE")"

  if [[ "$GAMMEL" -gt 0 ]]; then
    avvik "K11" "Workflowen logger inn med OIDC" \
          "Fant 'creds: \${{ secrets... }}' - det er varianten med client secret, ikke OIDC"
  elif [[ "$OIDC" -eq 0 ]]; then
    avvik "K11" "Workflowen logger inn med OIDC" \
          "Fant ikke 'permissions: id-token: write'. Uten den får ikke jobben OIDC-token"
  else
    ok "K11" "Workflowen er satt opp for OIDC (id-token: write, ingen creds:)"
  fi

  ENV_REF="$(antall_treff '^[[:space:]]*environment:' "$WF_MAPPE")"
  if [[ "$ENV_REF" -gt 0 ]]; then
    ok "K10" "Jobben deklarerer environment:"
  else
    avvik "K10" "Jobben deklarerer environment:" \
          "Uten 'environment:' matcher ikke federated credential scopet til environment"
  fi
fi

# --- K10: client secrets og subject (krever Azure) -------------------------

if [[ -n "$APP_ID" ]]; then
  SECRETS="$(az ad app credential list --id "$APP_ID" --query "length(@)" -o tsv 2>/dev/null)"
  if [[ "$SECRETS" == "0" ]]; then
    ok "K10" "App Registration har null client secrets"
  elif [[ -z "$SECRETS" ]]; then
    hoppet "K10" "Null client secrets" "Fikk ikke svar fra az. Er du logget inn, og er app-id riktig?"
  else
    avvik "K10" "Null client secrets" \
          "Fant $SECRETS client secret(s). Slett dem - hele poenget er at de ikke skal finnes"
  fi

  SUBJECTS="$(az ad app federated-credential list --id "$APP_ID" --query "[].subject" -o tsv 2>/dev/null)"
  if [[ -z "$SUBJECTS" ]]; then
    hoppet "K10" "Federated credential scopet til environment" "Fant ingen federated credentials"
  else
    FEIL_SCOPE="$(printf '%s\n' "$SUBJECTS" | grep -v ':environment:' | tr '\n' ' ')"
    HAR_TALL="$(printf '%s\n' "$SUBJECTS" | grep -cE ':[0-9]{6,}' || true)"
    if [[ -n "$FEIL_SCOPE" ]]; then
      avvik "K10" "Federated credential scopet til environment" \
            "Disse er ikke scopet til environment: ${FEIL_SCOPE}"
    elif [[ "$HAR_TALL" -gt 0 ]]; then
      avvik "K10" "Subject-strengen inneholder tall" \
            "Subject skal være repo:<org>/<repo>:environment:<miljø> uten ID-tall. Gir AADSTS700213"
    else
      ok "K10" "Federated credentials er scopet til environment"
    fi
  fi
else
  hoppet "K10" "Client secrets og subject-streng" "Kjør på nytt med --app-id <app-id>"
fi

# --- K11 og K12: må dokumenteres ------------------------------------------

manuell "K11" "az account show viser service principal, ikke deg" \
        "Lever utskriften fra workflowen ved siden av den lokale"
manuell "K12" "Andre kjøring gir No changes" \
        "Kjør workflowen to ganger uten å endre noe, og lever plan-utskriften"

# ===========================================================================
#  Oppsummering
# ===========================================================================

echo
printf '%s─────────────────────────────────────────────%s\n' "$GRA" "$SLUTT"
printf '  %sOK: %d%s   %sAvvik: %d%s   %sManuell: %d%s   %sHoppet over: %d%s\n' \
  "$GRONN" "$ANTALL_OK" "$SLUTT" "$ROD" "$ANTALL_AVVIK" "$SLUTT" \
  "$GUL" "$ANTALL_MANUELL" "$SLUTT" "$GRA" "$ANTALL_HOPPET" "$SLUTT"

if [[ "$ANTALL_AVVIK" -gt 0 ]]; then
  UNIKE="$(printf '%s\n' "${AVVIKSLISTE[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//')"
  printf '\n  Avvik på: %s\n' "$UNIKE"
  printf '  %sRett dem, og kjør skriptet på nytt.%s\n\n' "$GRA" "$SLUTT"
  exit 1
fi

if [[ "$ANTALL_HOPPET" -gt 0 ]]; then
  printf '\n  %sIngen avvik, men noen kontroller ble hoppet over.%s\n' "$GUL" "$SLUTT"
  printf '  %sKjør med --app-id og --storage-account før du leverer.%s\n\n' "$GRA" "$SLUTT"
  exit 0
fi

printf '\n  %sIngen avvik. Husk de manuelle utskriftene i innleveringen.%s\n\n' "$GRONN" "$SLUTT"
exit 0
