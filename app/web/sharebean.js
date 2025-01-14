function selectFile(contentType, multiple){
    return new Promise(resolve => {
        let input = document.createElement('input');
        input.type = 'file';
        input.multiple = multiple;
        input.accept = contentType;
        input.onchange = () => {
            let files = Array.from(input.files);
            if (multiple)
                resolve(files);
            else
                resolve(files[0]);
        };

        input.click();
    });
}
function humanSize( size ){
    if( size < 1024 ) {
        return size + 'B'
    } else if( size < 1024*1024 ) {
        return (size/1024).toFixed(2) + 'KB'
    } else if( size < 1024*1024*1024 ) {
        return (size/1024/1024).toFixed(2) + 'MB'
    } else {
        return (size/1024/1024/1024).toFixed(2) + 'GB'
    }
}

// tus upload job
let uploadJob = null



const messages = {
    en : {
        home : {
           title : 'SHAREBEAN',
           inputFolder : 'Please input folder name...',
           enter : 'ENTER',
           nameError : 'Folder name can only be lowercase letters and numbers.',
           tips: 'TIPS',
           ok : 'OK',
           cancel : 'CANCEL',
           error : 'ERROR!',
           success: 'SUCCESS!',
        } ,
        create : {
            title: 'CREATE FOLDER',
            inviteCode: 'Please input invite code...',
            create: 'CREATE',
            inviteError: 'Invite code error, create failed!'
        },
        upload : {
            set : 'SET',
            auth : 'AUTH',
            filename: 'Filename',
            size: 'Size',
            action: 'Action',
            download: 'DOWN',
            del: 'DEL',
            authFail: 'Auth fail, please auth again!',
            upload: 'UPLOAD',
            changePwd: 'Change password',
            hideRule: 'Hide rule',
            save: 'Save',
            close: 'Close',
            uploading: 'Uploading',
            sureDelete: 'Sure to delete file',
            inputAuth: 'Please input password...'
        }
    },
    zh : {
        home : {
            title : '分享豆',
            inputFolder : '请输入目录名...',
            enter : '进入',
            nameError : '目录名只能是小写字母和数字。',
            tips: '提示',
            ok : '确定',
            cancel : '取消',
            error: '错误!',
            success: '成功!'
        },
        create : {
            title: '创建目录',
            inviteCode: '请输入邀请码...',
            create: '创建',
            inviteError: '邀请码错误，创建失败!'
        },
        upload : {
            set : '设置',
            auth: '授权',
            filename: '文件名',
            size: '大小',
            action: '操作',
            download: '下载',
            del: '删除',
            authFail: '授权失败，请重新授权!',
            upload: '上传',
            changePwd: '修改密码',
            hideRule: '隐藏规则',
            save: '保存',
            close: '关闭',
            uploading: '上传中',
            sureDelete: '确定要删除文件',
            inputAuth: '请输入密码...'
        }
    }
}

function isZH() {
    let localLanguage = navigator.language || navigator.userLanguage;
    if( localLanguage.indexOf('zh')>=0 ) {
        return true
    }
    return false
}

const i18n = new VueI18n({
    locale: isZH() ? 'zh' : 'en',
    messages
})

Vue.use( VueI18n )

let app = new Vue({
    i18n,
    el: '#app',
    data: {
        title: 'welcome sharebean!',
        folder: '',
        files: [],
        auth: null,
        token: '',
        
        page: '',       //home   create   upload
        tips: '',
        iFolder: '',
        iPwd: '',
        iSPwd: '',
        iHide: '',
        
        dialog: null,
        dialogTitle: '',
        dialogMsg: '',

        uploadTips: '',
        uploadProgress: 0
    },
    methods:{
        reload(){
            location.reload()
        },
        checkInputFolder( name ) {
            name = name || this.iFolder
            if( /^[a-z0-9]+$/.test( name ) == false ) {
                this.tips = this.$t("home.nameError")
                return false
            }
            return true
        },

        async updatePathList( folder, token ) {
            folder = folder || this.folder
            token = token || ''

            let data = await this.callApi('list', {folder, token})
            
            if( data.code == 1) {
                this.enterHome()
            }else if(data.code == 2) {
                this.enterCreate()
            }else if(data.code == 200) {
                this.enterUpload( data )
            }
            
        },
        async onEnter(){
            if( this.checkInputFolder( this.iFolder ) == false ) return;
            window.location.href = '/' + this.iFolder
        },
        onHome() {
            window.location.href = '/'
        },
        async onCreate(){
            if( this.checkInputFolder( this.iFolder ) == false ) return;
            let data = await this.callApi('create', {folder:this.iFolder, spwd:this.iSPwd})

            if( data.code == 0 ) {
                this.updatePathList(this.folder)
            } else {
                return this.MessageBox(this.$t("create.inviteError"))
            }
        },

        async callApi(cmd, data) {
            let url = '/api/' + cmd
            let res = await fetch(url, {
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                    },
                method: "POST",
                body: JSON.stringify( data )
            })

            let ret = await res.json()
            console.warn( url, ret )
            return ret
        },

        onOpenUrl( url ) {
            window.open(url)
        },

        enterHome( tips ) {
            this.page = 'home'
            this.tips = tips || ''
        },
        enterCreate() {
            this.page = 'create'
        },
        enterUpload(data) {
            this.page = 'upload'
            this.setFiles( data.files )
            console.log( data.auth )
            this.auth = data.auth
        },
        setFiles( files ) {
            let arr = []
            for(let o of files) {
                arr.push({
                    hide: o.hide,
                    name: o.name,
                    size: o.size,
                    view: '/v/' + this.folder + '/' + o.name + '?token=' + this.token,
                    download: '/f/' + this.folder + '/' + o.name + '?token=' + this.token
                })
            }
            this.files = arr
        },
        async onDialogSet() {
            let result = await this.callApi('getset', {folder:this.folder, token:this.token})
            if( result.code != 0 ) {
                this.MessageBox(this.$t("home.error"))
                return this.reload()
            }
            this.iPwd = ''
            this.iHide = result.result.hide
            this.dialog = { 
                name: 'set' 
            }
        },
        async onSaveSet() {
            let result = await this.callApi('set', {folder:this.folder, pwd:btoa(this.iPwd), hide:this.iHide, token:this.token})
            if( result.code != 0 ) {
                await this.MessageBox(this.$t("home.error"))
                return this.reload();
            }
            this.saveToken( result.result.token )
            await this.MessageBox(this.$t('home.success'))
            this.reload()
        },

        async onAuth() {
            let result = await this.callApi('auth', {folder:this.folder, pwd:btoa(this.iPwd)})
            if( result.code!= 0 ) return this.MessageBox(this.$t("upload.authFail"))
            
            this.token = result.result.token
            this.auth = true
            this.saveToken( this.token )

            this.updatePathList( this.folder, this.token )
        },

        async onUpload() {
            let file = await selectFile('*/*', false)
            this.uploadFile( file )
            console.log( file )
        },

        async onDelete( name ) {
            let ret = await this.MessageBox(this.$t('upload.sureDelete') + ' 【' + name + ' 】?')
            if( ret == 0 ) return;
            let result = await this.callApi('del', {folder:this.folder, name, token:this.token})
            if( result.code!= 0 ) return this.MessageBox( $t("home.error") )
            this.updatePathList( this.folder, this.token )
        },

        MessageBox( msg) {
            return new Promise(resolve => {
                this.dialogTitle = this.$t("home.tips")
                this.dialogMsg = msg
                this.dialog = {
                    name:'msgbox',
                    ok: ()=>{
                        resolve(1)
                    },
                    cancel:()=>{
                        resolve(0)
                    }
                }
            })
        },

        onMessageBoxOK(){
            if(this.dialog && this.dialog.ok ) {
                this.dialog.ok()
            }
            this.dialog = null
        },

        onMessageBoxCancel(){
            if(this.dialog && this.dialog.cancel ) {
                this.dialog.cancel()
            }
            this.dialog = null
        },

        async uploadFile( file ) {
            let ret = await fetch('/api/tus', { method: 'OPTIONS' })
            if (ret.status != 204) {
                return console.log('Failed because:'+ ret.status);
            }
            let maxsize = ret.headers.get('Tus-Max-Size')
            if( maxsize == null ) {
                return console.log('Failed because: no max size');
            }
            maxsize = parseInt(maxsize)

            this.uploadProgress = 0
            // Create a new tus upload job
            uploadJob = new tus.Upload(file, {
                endpoint: '/api/tus',
                retryDelays: [5000],
                chunkSize: maxsize,
                metadata: { filename: file.name, filetype: file.type, folder: this.folder, path: '/' },
                onError: function (error) { console.log('Failed because: ' + error) },
                onProgress:  (bytesUploaded, bytesTotal) => {
                    var percentage = ((bytesUploaded / bytesTotal) * 100)
                    this.uploadProgress = percentage
                    this.uploadTips = '【' + file.name + '】' + this.$t('upload.uploading') + ' : ' + percentage.toFixed(2) + '%'
                },
                onSuccess: function () { 
                    location.reload();
                },
            })
            uploadJob.findPreviousUploads().then(function (previousUploads) {
                if (previousUploads.length) uploadJob.resumeFromPreviousUpload(previousUploads[0]);
                uploadJob.start()
            })
        },

        onCancelUpload() {
            if( uploadJob ) {
                uploadJob.abort()
                uploadJob = null
                this.uploadProgress = 0
                this.uploadTips = ''
            }
        },

        readToken(){
            return localStorage.getItem(this.folder + '_token') || ''
        },
        saveToken( token ) {
            localStorage.setItem(this.folder + '_token', token)
        }
    },
    mounted() {
        
        

        document.title = this.$t("home.title")
        let arr = window.location.pathname.split('/')
        if(arr.length>=2) {
            this.folder = arr[1]
            this.iFolder = arr[1]
        }
        if(this.folder == '') {
            this.enterHome()
        }else if(this.checkInputFolder( this.folder ) == false){
            return this.enterHome( this.$t("home.nameError") )
        }else {
            this.token = this.readToken()
            this.updatePathList( this.folder, this.token )
        }
    }
})