사용 방법:

스크립트 저장:

bashwget https://example.com/install_korean.sh
# 또는
curl -O https://example.com/install_korean.sh

실행 권한 부여:

bashchmod +x install_korean.sh

실행:

bashsudo ./install_korean.sh
설치되는 항목:

한글 폰트:

Noto Sans CJK
Nanum 폰트 (나눔고딕, 나눔명조)
은 폰트
백묵 폰트


입력기:

IBus + ibus-hangul


로케일:

ko_KR.UTF-8


환경 변수:

GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus



사용 후:

재부팅 또는 로그아웃/로그인
ibus-setup 실행하여 한글 추가
Shift + Space 또는 한/영 키로 전환

완전 자동화된 스크립트로 한 번에 모든 설정이 완료됩니다!
