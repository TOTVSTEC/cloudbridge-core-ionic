/*
/-------------------------------------------------------------\
| u_websck() - Exemplo de funcionamento do WebSocket          |
|-------------------------------------------------------------|
| Preferencialmente, utilize o codigo abaixo como base na sua |
| implementacao ADVPL, alterando apenas o trecho dentro do    |
| begin sequence ---- end sequence.                           |
|                                                             |
| Para utilizacao no projeto Cloudbridge Cordova-like, o nome |
| da funcao nao deve ser alterado (verificar o appserver.ini  |
| que define esta funcao como onstart).                       |
|                                                             |
|-------------------------------------------------------------|
| Autor - Daniel Otto Bolognani                               |
| Data  - 01/07/2017                                          |
\-------------------------------------------------------------/
*/
user function websck()
	Local nsServer, oError, ret, hasSend, txtRecv := ""
	Public nCon := 0

	// Inicia Websocket server em uma porta livre
	Public websck := TWEBSOCKET():NEW()
	nsServer := websck:StartServer(0)
	if nsServer != 0
		conout("Error starting WebSocket server (" + cvlatochar(nsServer) + ")")
		return
	endif

	// Error block recebera as falhas ocorridas na camada AdvPL e enviara ao JavaScript
	oError := ErrorBlock({ |e|u_errHandler(e:Description, websck, nCon) })

	// Entre em loop aguardando as mensagens vindas do JavaScript
	While .T.

		// Aguarda conexao
		if websck:nConnected() > 0

			// Recebe mensagem
			if websck:Receive(txtRecv, nCon, 500) == 0
				conout("Message Received from " + cvaltochar(nCon) + " - " + txtRecv)

				begin sequence
					// Parser do JSON
					oJson := tJsonParser():New()
					lenStrJson := Len(txtRecv)
					jsonfields := {}
					nRetParser := 0
					oJHM := .F.
					lRet := oJson:Json_Hash(txtRecv, lenStrJson, @jsonfields, @nRetParser, @oJHM)

					if !lRet
						websck:Send(MountJSON( "ADVPLERROR", "Invalid JSON"), ncon, 1000 )
					else
						cCode := ""
						cContent := ""
						cMsgRet := ""
						cCodRet := ""

						// Captura codigo e conteudo da mensagem
						lRet1 := HMGet(oJHM, "codMessage", cCode)
						lRet2 := HMGet(oJHM, "contentMessage", cContent)
						if lRet1 == .T. .AND. lRet2 == .T.
							DO CASE
								
								/*--------------------------------------------------------
								 INSIRA AQUI AS MENSAGENS ENVIADAS DO JAVASCRIPT AO ADVPL
								----------------------------------------------------------*/
								
								// Executa bloco de codigo AdvPL e retorna resultado
								CASE cCode == "execADVPL"
									bloco := &("{||" + cContent + "}")
									cMsgRet := cvaltochar( eval(bloco) )
									cCodRet := "returnADVPL"
									// Envia retorno do processamento a camada JavaScript
									jsonRes := MountJSON(cCodRet, cMsgRet)
									hasSend := websck:Send( jsonRes,nCon,500 )
									
							ENDCASE

						else
							hasSend := websck:Send(MountJSON( "ADVPLERROR", "Invalid JSON"), ncon, 1000 )
						endif

					endif
				end sequence

				// Exibe eventuais falhas no console
				if hasSend != 0
					conout("WebSocket Send error (" + cvaltochar(hasSend) + ")")
				endif

			endif
		else
			// Aguardando conexao
			websck:PingServer(500)
			conout("Waiting conection on port " + cvaltochar(websck:getport()))
		endif
	enddo

return

// Funcao para controle de erro
user function errHandler(sDescr, websck, ncon)
	websck:Send(MountJSON( "ADVPLERROR", sDescr), ncon, 1000 )
	Break
RETURN

// Monta JSON de resposta
static function MountJSON(CCode, CContent)
	jsonResult := '{ "codMessage": "' + CCode + '", "contentMessage": "' + CContent + '" }'
return jsonResult
