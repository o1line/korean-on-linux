#!/bin/bash
# ============================================================
# 리눅스 한글 입출력 자동 설치 스크립트
# 모든 주요 배포판 지원 (Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE 등)
# ============================================================

set -e  # 에러 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# 로그 함수
# ============================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================
# 배포판 감지 함수
# ============================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        DISTRO_VERSION=$DISTRIB_RELEASE
    else
        DISTRO=$(uname -s)
        DISTRO_VERSION=$(uname -r)
    fi
    
    # 소문자로 변환
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
    
    log_info "감지된 배포판: $DISTRO $DISTRO_VERSION"
}

# ============================================================
# 패키지 관리자 감지
# ============================================================
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
    elif command -v emerge &> /dev/null; then
        PKG_MANAGER="emerge"
    else
        log_error "지원되지 않는 패키지 관리자입니다."
        exit 1
    fi
    
    log_info "패키지 관리자: $PKG_MANAGER"
}

# ============================================================
# 루트 권한 확인
# ============================================================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "이 스크립트는 root 권한이 필요합니다."
        log_info "다음 명령으로 다시 실행하세요: sudo $0"
        exit 1
    fi
}

# ============================================================
# 패키지 업데이트
# ============================================================
update_system() {
    log_info "시스템 패키지 업데이트 중..."
    
    case $PKG_MANAGER in
        apt)
            apt-get update -y
            ;;
        dnf)
            dnf check-update -y || true
            ;;
        yum)
            yum check-update -y || true
            ;;
        pacman)
            pacman -Sy --noconfirm
            ;;
        zypper)
            zypper refresh
            ;;
        emerge)
            emerge --sync
            ;;
    esac
    
    log_success "시스템 업데이트 완료"
}

# ============================================================
# 한글 폰트 설치
# ============================================================
install_fonts() {
    log_info "한글 폰트 설치 중..."
    
    case $PKG_MANAGER in
        apt)
            # Ubuntu, Debian
            apt-get install -y \
                fonts-nanum \
                fonts-nanum-coding \
                fonts-nanum-extra \
                fonts-noto-cjk \
                fonts-noto-cjk-extra \
                fonts-unfonts-core \
                fonts-baekmuk
            ;;
        dnf)
            # Fedora
			dnf install -y \
                google-noto-sans-cjk-ttc-fonts \
                google-noto-serif-cjk-ttc-fonts
            dnf install fontconfig -y
			curl -o nanumfont.zip http://cdn.naver.com/naver/NanumFont/fontfiles/NanumFont_TTF_ALL.zip
			unzip -d /usr/share/fonts/nanum nanumfont.zip
            ;;
        yum)
            # CentOS, RHEL
            yum install -y \
                google-noto-sans-cjk-ttc-fonts \
                google-noto-serif-cjk-ttc-fonts \
                nhn-nanum-gothic-fonts \
                nhn-nanum-myeongjo-fonts || \
            yum install -y \
                @fonts \
                dejavu-fonts \
                liberation-fonts
            ;;
        pacman)
            # Arch Linux
            pacman -S --noconfirm \
                noto-fonts-cjk \
                ttf-nanum \
                ttf-baekmuk \
                adobe-source-han-sans-kr-fonts \
                adobe-source-han-serif-kr-fonts
            ;;
        zypper)
            # openSUSE
            zypper install -y \
                google-noto-sans-cjk-fonts \
                naver-nanum-fonts \
                un-fonts
            ;;
        emerge)
            # Gentoo
            emerge media-fonts/noto-cjk \
                media-fonts/nanum \
                media-fonts/baekmuk-fonts
            ;;
    esac
    
    log_success "한글 폰트 설치 완료"
}

# ============================================================
# 한글 입력기 (IBus + Hangul) 설치
# ============================================================
install_ibus_hangul() {
    log_info "IBus 한글 입력기 설치 중..."
    
    case $PKG_MANAGER in
        apt)
            apt-get install -y \
                ibus \
                ibus-hangul \
                im-config
            ;;
        dnf)
            dnf install -y \
                ibus \
                ibus-hangul \
                ibus-setup
            ;;
        yum)
            yum install -y \
                ibus \
                ibus-hangul \
                ibus-setup
            ;;
        pacman)
            pacman -S --noconfirm \
                ibus \
                ibus-hangul
            ;;
        zypper)
            zypper install -y \
                ibus \
                ibus-hangul
            ;;
        emerge)
            emerge app-i18n/ibus \
                app-i18n/ibus-hangul
            ;;
    esac
    
    log_success "IBus 한글 입력기 설치 완료"
}

# ============================================================
# Fcitx 한글 입력기 설치 (선택 사항)
# ============================================================
install_fcitx_hangul() {
    log_info "Fcitx 한글 입력기 설치 중..."
    
    case $PKG_MANAGER in
        apt)
            apt-get install -y \
                fcitx \
                fcitx-hangul \
                fcitx-config-gtk
            ;;
        dnf)
            dnf install -y \
                fcitx \
                fcitx-hangul \
                fcitx-configtool
            ;;
        yum)
            yum install -y \
                fcitx \
                fcitx-hangul || \
            log_warning "Fcitx는 이 배포판에서 사용 가능하지 않을 수 있습니다."
            ;;
        pacman)
            pacman -S --noconfirm \
                fcitx \
                fcitx-hangul \
                fcitx-configtool
            ;;
        zypper)
            zypper install -y \
                fcitx \
                fcitx-hangul
            ;;
        emerge)
            emerge app-i18n/fcitx \
                app-i18n/fcitx-hangul
            ;;
    esac
    
    log_success "Fcitx 한글 입력기 설치 완료 (선택 사항)"
}

# ============================================================
# 로케일 설정
# ============================================================
configure_locale() {
    log_info "한글 로케일 설정 중..."
    
    # 로케일 생성
    if [ -f /etc/locale.gen ]; then
        # locale.gen 파일이 있는 경우 (Debian, Ubuntu, Arch 등)
        sed -i 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || \
        echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen
        
        if command -v locale-gen &> /dev/null; then
            locale-gen
        fi
    fi
    
    # 로케일 설치
    case $PKG_MANAGER in
        apt)
            apt-get install -y language-pack-ko || \
            apt-get install -y locales
            ;;
        dnf|yum)
            dnf install -y glibc-langpack-ko 2>/dev/null || \
            yum install -y glibc-langpack-ko 2>/dev/null || \
            log_warning "언어팩 설치 실패 (일부 배포판에서는 정상)"
            ;;
        pacman)
            # Arch는 locale-gen으로 충분
            :
            ;;
        zypper)
            zypper install -y glibc-locale
            ;;
    esac
    
    log_success "로케일 설정 완료"
}

# ============================================================
# 환경 변수 설정
# ============================================================
configure_environment() {
    log_info "환경 변수 설정 중..."
    
    # /etc/environment 설정
    if ! grep -q "GTK_IM_MODULE" /etc/environment 2>/dev/null; then
        cat >> /etc/environment << 'EOF'

# Korean Input Method
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
EOF
    fi
    
    # 사용자별 설정 (.bashrc, .profile)
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            # .bashrc에 추가
            if [ -f "$user_home/.bashrc" ]; then
                if ! grep -q "GTK_IM_MODULE" "$user_home/.bashrc" 2>/dev/null; then
                    cat >> "$user_home/.bashrc" << 'EOF'

# Korean Input Method
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
                    chown $username:$username "$user_home/.bashrc"
                fi
            fi
            
            # .profile에 추가
            if [ -f "$user_home/.profile" ]; then
                if ! grep -q "ibus-daemon" "$user_home/.profile" 2>/dev/null; then
                    cat >> "$user_home/.profile" << 'EOF'

# Start IBus daemon
if [ -z "$IBUS_DAEMON_RUNNING" ]; then
    export IBUS_DAEMON_RUNNING=1
    ibus-daemon -drx &
fi
EOF
                    chown $username:$username "$user_home/.profile"
                fi
            fi
        fi
    done
    
    # root 사용자 설정
    if [ -f /root/.bashrc ]; then
        if ! grep -q "GTK_IM_MODULE" /root/.bashrc 2>/dev/null; then
            cat >> /root/.bashrc << 'EOF'

# Korean Input Method
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
        fi
    fi
    
    log_success "환경 변수 설정 완료"
}

# ============================================================
# IBus 설정
# ============================================================
configure_ibus() {
    log_info "IBus 설정 중..."
    
    # 모든 사용자에 대해 IBus 한글 엔진 추가
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            # .config 디렉토리 생성
            mkdir -p "$user_home/.config/ibus"
            
            # IBus 설정 파일 생성
            cat > "$user_home/.config/ibus/config" << 'EOF'
[general]
preload-engines = ['hangul']
engines-order = ['hangul', 'xkb:us::eng']
switcher-delay-time = 400

[engine/hangul]
auto-reorder = true
hanja-key = Hangul_Hanja
EOF
            
            chown -R $username:$username "$user_home/.config/ibus"
        fi
    done
    
    log_success "IBus 설정 완료"
}

# ============================================================
# 폰트 캐시 재생성
# ============================================================
rebuild_font_cache() {
    log_info "폰트 캐시 재생성 중..."
    
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv
        log_success "폰트 캐시 재생성 완료"
    else
        log_warning "fc-cache 명령을 찾을 수 없습니다."
    fi
}

# ============================================================
# 설치 완료 메시지 및 안내
# ============================================================
print_final_message() {
    echo ""
    echo "============================================================"
    log_success "한글 입출력 설치가 완료되었습니다!"
    echo "============================================================"
    echo ""
    echo -e "${YELLOW}다음 단계:${NC}"
    echo ""
    echo "1. 시스템을 재부팅하거나 로그아웃 후 다시 로그인하세요."
    echo "   ${BLUE}sudo reboot${NC}"
    echo ""
    echo "2. IBus 설정:"
    echo "   - 터미널에서 ${BLUE}ibus-setup${NC} 실행"
    echo "   - 'Input Method' 탭에서 'Add' 클릭"
    echo "   - 'Korean - Hangul' 선택"
    echo ""
    echo "3. 한글 입력 전환:"
    echo "   - ${BLUE}Shift + Space${NC} 또는 ${BLUE}Hangul${NC} 키"
    echo "   - ${BLUE}Super + Space${NC} (일부 환경)"
    echo ""
    echo "4. 데스크톱 환경별 추가 설정:"
    echo "   - GNOME: Settings → Region & Language → Input Sources"
    echo "   - KDE: System Settings → Input Devices → Keyboard"
    echo "   - XFCE: Settings → Keyboard → Layout"
    echo ""
    echo "5. 문제 발생 시:"
    echo "   - IBus 데몬 수동 시작: ${BLUE}ibus-daemon -drx${NC}"
    echo "   - 로그 확인: ${BLUE}journalctl -xe${NC}"
    echo "   - 환경 변수 확인: ${BLUE}env | grep IM${NC}"
    echo ""
    echo "============================================================"
    echo ""
}

# ============================================================
# 메인 함수
# ============================================================
main() {
    echo "============================================================"
    echo "    리눅스 한글 입출력 자동 설치 스크립트"
    echo "============================================================"
    echo ""
    
    # 1. 루트 권한 확인
    check_root
    
    # 2. 배포판 감지
    detect_distro
    
    # 3. 패키지 관리자 감지
    detect_package_manager
    
    # 4. 시스템 업데이트
    update_system
    
    # 5. 한글 폰트 설치
    install_fonts
    
    # 6. 로케일 설정
    configure_locale
    
    # 7. IBus 한글 입력기 설치
    install_ibus_hangul
    
    # 8. 환경 변수 설정
    configure_environment
    
    # 9. IBus 설정
    configure_ibus
    
    # 10. 폰트 캐시 재생성
    rebuild_font_cache
    
    # 11. 완료 메시지
    print_final_message
}

# ============================================================
# 스크립트 실행
# ============================================================
main "$@"
